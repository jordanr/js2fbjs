require 'js_processor'

class FbjsRewriter < JsProcessor
  def self.translate(str, tag=nil)
    require 'rkelly'
    begin
      ans = self.new(tag).process(RKelly::Parser.new.parse(str).to_sexp)
    rescue
      $stderr.puts "WARNING: processing error on '#{str}'"
      ans = str
    end

    if(ans.empty?)
      $stderr.puts "WARNING: parse error on '#{str}'"
      str
    else
      ans
    end
  end

  def initialize(tag)
    super()
    @tag = tag
  end

  def process exp
    exp = Sexp.from_array(exp) if Array === exp unless Sexp === exp
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

    # style => getStyle('width'), setStyle('width', '10px'), ...
    STYLE = 'style'

    # innerText && textContent => setTextValue
    #    SPECIALS = {
    #	{ 'innerText' => 'setTextValue' },
    #	{ 'textContent' => 'setTextValue' }
    #}
    # innerHtml => setInnerFBML || setInnerXHTML
    # AMBIGUOUS = { 'innerHtml' => 'setInnerFBML' }

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
    # For <form> tags
    # -> __dlg.onconfirm = function() { __obj.form.submit(); } return false;
    CONFIRM_FORM_CALLBACK = s(:FunctionCall, s(:DotAccessor, s(:DotAccessor, s(:Resolve, THIS_VAR), 'form'), 'submit'), s(:Arguments))
    # For <a> tags
    # -> __dlg.onconfirm = function() { document.location = __obj.href; } return false;
    CONFIRM_LINK_CALLBACK = s(:OpEqual, s(:DotAccessor, s(:Resolve, 'document'), 'location'), 
					s(:DotAccessor, s(:Resolve, THIS_VAR)  , 'href') )
    FORM = 'form'
    LINK = 'a'
    FUNCTION = 'function'
    # Undefined 
    # getAbsoluteTop 	Returns the elements absolute position relative to the top of the page. Useful because of lack of offsetParent support.
    # getAbsoluteLeft 	Same as getAbsoluteTop, but horizontally. 
    # getRootElement 	used as document.getRootElement - returns the top-level element of your profile box or canvas page

  # Takes care of:
  # * banned getters
  # * get style
  def rewrite_DotAccessor(exp)
    if(GETTERS.include?(exp.last))
      generate_etter(exp[1],exp.last, s(:Arguments), GET)
    elsif(style?(exp)) #  s(:dot, s(:dot, .., style), accessor)
      dot2 = exp[1] # has base, STYLE accessor
      arg = exp.last
      generate_etter(dot2[1], STYLE, s(:Arguments, s(:String, "'#{arg}'")), GET)
    else
      exp
    end
  end	

  # Takes care of:
  # * confirms with no callbacks
  def rewrite_ExpressionStatement(exp)
    if(confirm?(exp.last) )	
        generate_confirm(exp.last) || exp
    else	
	exp
    end
  end

  # Takes care of:
  # * setAttribute
  def rewrite_FunctionCall(exp)
    if(set_attribute?(exp))
	dot = exp[1]
	if not type?(exp.last, :Arguments) or (exp.last.length != SET_ATTR_ARGS)
	  $stderr.puts "WARNING: Tried to rewrite #{SET_ATTR} with #{exp.last.length} length instead of #{SET_ATTR_ARGS}" 
          exp
	else	  
	  attribute = exp.last[1].last 
          attribute.gsub!(/'([a-z]+)'/,'\1')
	  generate_etter(dot[1], attribute, s(:Arguments, exp.last.pop))
	end
    else	
	exp
    end
  end

  # TODO: Formatting issues with indention line breaks
  # Takes care of:
  # * confirms with callback(s)
  def rewrite_If(exp)
    if(confirm?(exp[1]))
      confirm = generate_confirm(exp[1])
      return exp if confirm.nil? # return if nil
      ifff = generate_event(exp[2].last.gsub(s(:This,'this'), s(:Resolve,THIS_VAR)), DIALOG_VAR, ONCONFIRM)
      result = s(:dummy, generate_var_assign(THIS_VAR, s(:This, 'this')), confirm, ifff)
      if(exp[3])
        result.push( generate_event(exp[3].last.gsub(s(:This,'this'), s(:Resolve,THIS_VAR)), DIALOG_VAR, ONCANCEL))
      else
        result
      end
    else
      exp
    end
  end

  # Takes care of:
  # * banned setters
  # * set style
  def rewrite_OpEqual(exp)
    if(etter?(exp[1], SET) )
      dot = exp[1]
      generate_etter(dot[1],dot[2], exp.pop)
    elsif(style?(exp[1]) )
      dot1 = exp[1] # has new arg
      dot2 = dot1[1] # has base, STYLE accessor
      generate_etter(dot2[1], STYLE,  s(:Arguments, s(:String, "'#{dot1.last}'"), exp.pop) )
    else
      exp	
    end
  end

  # For <form> tags
  # -> __dlg.onconfirm = function() { this.form.submit(); } return false;
  # For <a> tags
  # -> __dlg.onconfirm = function() { document.location = this.href; } return false;
  # Takes care of:
  # * return confirm("...");
  def rewrite_Return(exp)
    if(confirm?(exp.last))
      confirm = generate_confirm(exp.last)
      return exp if confirm.nil? # return if nil
      result = s(:dummy)
      if(@tag==FORM) 
	result.push(generate_var_assign(THIS_VAR, s(:This, 'this')) )
	result.push(confirm)
	result.push(generate_event(CONFIRM_FORM_CALLBACK, DIALOG_VAR, ONCONFIRM))
      elsif(@tag==LINK) 
	result.push(generate_var_assign(THIS_VAR, s(:This, 'this')) )
	result.push(confirm)
	result.push(generate_event(CONFIRM_LINK_CALLBACK, DIALOG_VAR, ONCONFIRM))
      else
	result.push(confirm)
      end
      result.push(s(:Return, s(:False, 'false')) )
    else
      exp
    end
  end

  private
  ############################################################
  # Generators
  
  # If the confirm statement doesn't have just a message, then return nil.
  # Else return a Facebook confirm dialog.
  # var __dlg = new Dialog().showMessage("...");
  def generate_confirm(exp)
    if(not type?(exp.last, :Arguments) or (exp.last.length != DIALOG_ARGS) )
      $stderr.puts "WARNING: Tried to rewrite #{CONFIRM} with #{exp.last.length} length instead of #{DIALOG_ARGS}" 
      return nil
    end
    generate_var_assign(DIALOG_VAR,  s(:FunctionCall, 
	s(:DotAccessor, s(:NewExpr, s(:Resolve, DIALOG)), CONFIRM_ACCESSOR),
	s(:Arguments, s(:String, "'#{DIALOG_TITLE}'"), exp.pop) 
    ) )
  end

  # var.event = function() { ... }
  def generate_event(exp, var, event)
    s(:OpEqual, s(:DotAccessor, s(:Resolve, var), event),
		s(:FunctionExpr, FUNCTION, s() , s(:FunctionBody, exp))
    )
  end

  # object.getAccessor(), object.setAccessor(args)
  def generate_etter(object, accessor, args, set_or_get=SET)
    s(:FunctionCall, s(:DotAccessor, object, etter(accessor, set_or_get) ), args )
  end

  # var name = ...;
  def generate_var_assign(name, exp)
    s(:VarStatement, s(:VarDecl, name, s(:AssignExpr, exp) )  )
  end
  ############################################################
  # Utility Methods: 
  def style?(exp)
    type?(exp, :DotAccessor) && type?(exp[1], :DotAccessor) && exp[1].last == STYLE
  end

  def set_attribute?(exp)
    type?(exp, :FunctionCall)&& type?(exp[1], :DotAccessor) && exp[1].last==SET_ATTR
  end

  def confirm?(exp)
    type?(exp, :FunctionCall) && type?(exp[1], :Resolve) && exp[1].last==CONFIRM
  end


  def etter?(exp, set_or_get)
    if(set_or_get == SET)
      type?(exp, :DotAccessor) && SETTERS.include?(exp.last)
    elsif(set_or_get == GET)
      type?(exp, :DotAccessor) && GETTERS.include?(exp.last)
    else
      raise StandardError
    end
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

