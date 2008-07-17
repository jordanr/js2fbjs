require 'js_processor'

class FbjsRewriter < JsProcessor

  def process exp
    exp = Sexp.from_array(exp) if Array === exp unless Sexp === exp
#    p exp
    super exp
  end

  ############################################################
  # Processors  

  # See js_processor

  ############################################################
  # Rewriters:

    # Getters and Setters
    ONLY_GETTERS = %w{
        parentNode nextSibling previousSibling firstChild lastChild childNodes
        clientWidth clientHeight offsetWidth offsetHeight scrollHeight scrollWidth
        form tagName
    }
    ONLY_SETTERS = %w{
        location
    }
    BOTH_GETTERS_AND_SETTERS = %w{
        action value href src className id dir checked scrollTop scrollLeft tabIndex
        title name cols rows accessKey disabled readOnly type selectedIndex
        selected target method
    }
    GETTERS = ONLY_GETTERS + BOTH_GETTERS_AND_SETTERS
    SETTERS = ONLY_SETTERS + BOTH_GETTERS_AND_SETTERS
    SET = 'set'
    GET = 'get'
    # setAttribute => setName, setValue, ...
    SET_ATTR = 'setAttribute'
    SET_ATTR_ARGS = 3

    # style => getWidth, setWidth, getColor, setColor, ...
    STYLE = 'style'

    # innerText, textContent => setTextValue
    SPECIALS = {
	{ 'innerText' => 'setTextValue' },
	{ 'textContent' => 'setTextValue' }
    }
    # innerHtml => setInnerFBML, setInnerXHTML
    AMBIGUOUS = { 'innerHtml' => 'setInnerFBML' }

    # Dialogs
    DIALOG = 'Dialog'
    DIALOG_TITLE = 'The page says:'
    DIALOG_ARGS = 2
    CONFIRM = 'confirm'
    CONFIRM_ACCESSOR = 'showChoice'
    ALERT = 'alert' 
    ALERT_ACCESSOR = 'showMessage'
    THIS_VAR = '__obj'
    DIALOG_VAR = '__dlg'   
    ONCONFIRM = 'onconfirm' 
    ONCANCEL = 'oncancel'

  # Takes care of:
  # * banned setters
  # * style
  def rewrite_OpEqual(exp)
    if(type?(exp[1], :DotAccessor) && SETTERS.include?(exp[1].last))
      exp.shift # get rid of type
      dot = exp.shift
      s(:FunctionCall, s(dot.shift, dot.shift, etter(dot.shift) ), exp.shift )
    elsif(type?(exp[1], :DotAccessor) && type?(exp[1][1], :DotAccessor) && exp[1][1].last == STYLE)
      exp.shift # rid of type
      dot1 = exp.shift # has new arg
      dot1.shift # rid of type
      dot2 = dot1.shift # has base, STYLE accessor
      arg = exp.shift
      s(:FunctionCall, s(dot2.shift, dot2.shift, etter(STYLE)), s(:Arguments, s(:String, "'#{dot1.last}'"), arg) )
    else
      exp	
    end
  end

  # Takes care of:
  # * banned getters
  def rewrite_DotAccessor(exp)
    if(GETTERS.include?(exp.last))
      s(:FunctionCall, s(exp.shift, exp.shift, etter(exp.shift, GET) ), s(:Arguments) )
    else
      exp
    end
  end	

  # Takes care of:
  # * setAttribute
  # * confirms with no callback
  def rewrite_FunctionCall(exp)
    if(type?(exp[1], :DotAccessor) && exp[1].last==SET_ATTR)
	dot = exp[1]
	if not type?(exp.last, :Arguments) or (exp.last.length != SET_ATTR_ARGS)
	  $stderr.puts "WARNING: Tried to rewrite #{SET_ATTR} with #{exp.last.length} length instead of #{SET_ATTR_ARGS}" 
          exp
	else
	  type = exp.last.shift # :Arguments
	  attribute = exp.last.shift.last
          attribute.gsub!(/'([a-z]+)'/,'\1')
          s(exp.shift, s(dot.shift, dot.shift, etter(attribute)), s(type,exp.last.shift))
	end
    elsif(confirm?(exp) ) # must be last elsif, see confirm?
      generate_confirm(exp)
    else	
	exp
    end
  end

  # TODO: Formatting issues with indention line breaks
  # Takes care of:
  # * confirms with callback(s)
  def rewrite_If(exp)
    if(confirm?(exp[1]))
	exp.shift # :If
	x = s(:dummy, generate_var_assign(THIS_VAR, s(:This, 'this')),
			   generate_confirm(exp.shift)
        )
	x.push(generate_event(exp.shift.last.gsub(s(:This, 'this'),s(:Resolve, THIS_VAR)), DIALOG_VAR, ONCONFIRM)) # use .last to remove extra block
 	x.push(generate_event(exp.shift.gsub(s(:This,'this'),s(:Resolve,THIS_VAR)), DIALOG_VAR, ONCANCEL)) if(exp.first)
	x
    else
	exp
    end
  end

  private
  ############################################################
  # Generators
  def generate_confirm(exp)
    generate_var_assign(DIALOG_VAR,  s(:FunctionCall, 
	s(:DotAccessor, s(:NewExpr, s(:Resolve, DIALOG)), CONFIRM_ACCESSOR),
	s(:Arguments, s(:String, "'#{DIALOG_TITLE}'"), exp.pop) 
    ) )
  end

  def generate_event(exp, var, event)
    s(:OpEqual, s(:DotAccessor, s(:Resolve, var), event),
		s(:FunctionExpr, '', s() , s(:FunctionBody, exp))
    )
  end

  def generate_var_assign(name, exp)
    s(:VarStatement, s(:VarDecl, name, s(:AssignExpr, exp) )  )
  end
  ############################################################
  # Utility Methods: 
  def confirm?(list)
    if( type?(list, :FunctionCall) && type?(list[1], :Resolve) && list[1].last==CONFIRM )
	return true unless(not type?(list.last, :Arguments) or (list.last.length != DIALOG_ARGS) )
        $stderr.puts "WARNING: Tried to rewrite #{CONFIRM} with #{list.last.length} length instead of #{DIALOG_ARGS}" 
	return false
    end
    return false
  end

  # change attribute to getter or setter 
  def etter(attribute, set_or_get=SET)
    attribute = attribute[0,1].upcase + attribute[1,attribute.length] if(set_or_get)
    "#{set_or_get}#{attribute}"
  end

  def type?(list, typ)
    (Array === list) && (list.first == typ)
  end
end

