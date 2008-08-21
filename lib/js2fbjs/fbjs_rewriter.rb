require 'js2fbjs/js_processor'
require 'js2fbjs/sexp'
module Js2Fbjs

# Rewrites JavaScript to be OK for Facebook.  Handles,
# * confirm("...") to new Dialog().showChoice(...).onclick= ...
# * DOM attributes (href, location, ...) => getters/setters
# * setAttribute => setWidth, setAction, ...
# * style.attribute => setStyle("attribute",...) or getStyle("attribute")
class FbjsRewriter < JsProcessor
  include SexpUtility, SexpMatchSpecials

  # Errors  
  class AmbiguousAccessorError < StandardError; end
  class BannedExtendError < StandardError; end
  class BannedObjectError < StandardError; end

  # Takes the JavaScript and possibly what tag it's found in.
  def self.translate(str, tag=nil, strict = false)
    fbjstree = Js2Fbjs::Parser.new(strict).parse(str)
    fbjs = self.new(tag).process(fbjstree)
    raise SexpProcessorError, "translation is the empty string" if (fbjs.nil? || fbjs.empty?) and !str.empty?
    fbjs
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
  # Tokens:
    # objects, add more
    JS_BASE_OBJECTS = %w{
	Array Boolean Date Error Function Math Number Object RegExp String 
    }
    # From  http://www.w3schools.com/js/js_obj_htmldom.asp
    JS_DOM_OBJECTS = %w{
	Document Anchor Area Base Body Button Event Form Frame Frameset Iframe
	Image Link Meta Option Select Style Table TableData TableRow Textarea
	Window Navigator Screen History Location
    }
    BANNED_EXTENDORS = JS_BASE_OBJECTS + JS_DOM_OBJECTS
  
    BANNED_OBJECTS = %w{ window }
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
    SET_ATTR_ARGS = 2

    # style => getStyle('width'), setStyle('width', '10px'), ...
    STYLE = 'style'

    # innerText && textContent => setTextValue
    SPECIAL_SETTERS = { 
	'innerText' => 'setTextValue' , 
	'textContent' => 'setTextValue' }
    
    # innerHtml => setInnerFBML || setInnerXHTML
    AMBIGUOUS = { 'innerHtml' => ['setInnerFBML', 'setInnerXHTML'] }

    # Dialogs
    DIALOG = 'Dialog'
    DIALOG_TITLE = 'The page says:'
    DIALOG_ARGS = 1
    CONFIRM = 'confirm'

    CONFIRM_ACCESSOR = 'showChoice'
    ALERT = 'alert' 
    ALERT_ACCESSOR = 'showMessage'
    THIS_VAR = '__obj'
    DIALOG_VAR = '__dlg'   
    ONCONFIRM = 'onconfirm' 
    ONCANCEL = 'oncancel'
    FORM = 'input'
    LINK = 'a'
    FUNCTION = 'function'
    PROTOTYPE = 'prototype'

    # Undefined 
    # getAbsoluteTop 	Returns the elements absolute position relative to the top of the page. Useful because of lack of offsetParent support.
    # getAbsoluteLeft 	Same as getAbsoluteTop, but horizontally. 
    # getRootElement 	used as document.getRootElement - returns the top-level element of your profile box or canvas page

  ############################################################
  # Rewriters:

  # Takes care of:
  # * banned getters
  # * get style
  def rewrite_DotAccessor(exp)
    case(exp)
     when BANNED_EXTEND_DOT(): raise BannedExtendError, "cannot prototype built in objects like #{exp[1].last}"
     when AMBIGUOUS_DOT(): raise AmbiguousAccessorError, "#{exp.last} could be #{AMBIGUOUS[exp.last].join(' or ')}"
     when BANNED_OBJECT_DOT(): raise BannedObjectError, "cannot use #{exp[1].last} ever"
     when GETTER_DOT(): generate_getter(exp[1], exp.last)
     when STYLE_DOT(): generate_get_style(exp[1][1], exp.last)
     else exp
    end
  end

  # Takes care of:
  # * confirm(message) => var __dlg = new Dialog().showChoice(TITLE, message);
  # * alert(message)   => var __dlg = new Dialog().showMessage(TITLE, message);
  def rewrite_ExpressionStatement(exp)
    case(exp)
      when CONFIRM_EXP(): generate_confirm(exp.last) || exp
      when ALERT_EXP(): generate_alert(exp.last) || exp
      else exp
    end
  end

  # Takes care of:
  # * setAttribute
  def rewrite_FunctionCall(exp)
    case(exp)
      when SET_ATTRIBUTE_CALL():
	dot = exp[1]
	if not type?(exp.last, :Arguments) or (exp.last.length-1 != SET_ATTR_ARGS) # user defined func
          exp
	else	  
	  attribute = exp.last[1].last 
          attribute.gsub!(/'([a-z]+)'/,'\1')
	  generate_setter(dot[1], attribute, exp.last.pop)
	end
      else exp
    end
  end

  # TODO: Formatting issues with indention line breaks
  # Takes care of:
  # * confirms with callback(s)
  def rewrite_If(exp)
    case(exp)
      when CONFIRM_IF(): #confirm?(exp[1]))
        confirm = generate_confirm(exp[1])
        return exp if confirm.nil? # return if nil, emit a bad confirm warning
        if_body = type?(exp[2], :Block) ? exp[2].last : exp[2] # get_rid_of_extra_block(
        if_event = generate_event(if_body.gsub(s(:This,'this'), s(:Resolve,THIS_VAR)), DIALOG_VAR, ONCONFIRM)
        result = s(:dummy, generate_var_assign(THIS_VAR, s(:This, 'this')), confirm, if_event)
      when CONFIRM_IF_ELSE():
        confirm = generate_confirm(exp[1])
        return exp if confirm.nil? # return if nil, emit a bad confirm warning
        if_body = type?(exp[2], :Block) ? exp[2].last : exp[2] # get_rid_of_extra_block(
        if_event = generate_event(if_body.gsub(s(:This,'this'), s(:Resolve,THIS_VAR)), DIALOG_VAR, ONCONFIRM)
        result = s(:dummy, generate_var_assign(THIS_VAR, s(:This, 'this')), confirm, if_event)
        else_body = type?(exp[3], :Block) ? exp[3].last : exp[3] # get_rid_of_extra_block
        result.push( generate_event(else_body.gsub(s(:This,'this'), s(:Resolve,THIS_VAR)), DIALOG_VAR, ONCANCEL))
      else exp
    end
  end

  # Takes care of:
  # * obj.setter = value => obj.setSetter(value);
  # * obj.special_key = value => obj.setSpecialKeyValue(value);
  # * obj.style.attr = value => obj.setStyle(value); 
  def rewrite_OpEqual(exp)
    case(exp)
      when SET_OP_EQUAL(): generate_setter(exp[1][1], exp[1][2], exp.last)
      when SPECIAL_OP_EQUAL(): generate_etter(exp[1][1], SPECIAL_SETTERS[exp[1][2]], exp.last, nil)
      when STYLE_OP_EQUAL(): generate_etter(exp[1][1][1], STYLE, s(:Arguments, s(:String, "'#{exp[1].last}'"), exp.last))
      else exp	
    end
  end

  # Takes care of:
  # * return confirm("...");
  #
  # == Returns
  # For <input> tags
  # -> var __obj = this; var __dlg = new Dialog.showChoice("The page says:", "...");
  #    __dlg.onconfirm = function() { __obj.getForm().submit(); }; return false;
  # For <a> tags
  # -> var __obj = this; var __dlg = new Dialog.showChoice("The page says:", "...");
  #    __dlg.onconfirm = function() { document.setLocation(__obj.getHref()); }; return false;
  def rewrite_Return(exp)
    case(exp)
      when CONFIRM_RETURN(): #if(confirm?(exp.last))
        confirm = generate_confirm(exp.last)
        return exp if confirm.nil? # return if nil
        result = s(:dummy)
	case(@tag)
          when FORM:
   	    result.push(generate_var_assign(THIS_VAR, s(:This, 'this')) )
     	    result.push(confirm)
 	    result.push(generate_event(generate_confirm_form_callback(), DIALOG_VAR, ONCONFIRM))
          when LINK:
	    result.push(generate_var_assign(THIS_VAR, s(:This, 'this')) )
       	    result.push(confirm)
	    result.push(generate_event(generate_confirm_link_callback(), DIALOG_VAR, ONCONFIRM))
          else	result.push(confirm)
        end 
        result.push(s(:Return, s(:False, 'false')) )
      else exp
    end
  end

  private
  ############################################################
  # Generators
  
  # If the confirm statement doesn't have just a message, then return nil.
  # Else return a Facebook confirm dialog.
  # var __dlg = new Dialog().showChoice("...");
  def generate_confirm(exp)
    if(not type?(exp.last, :Arguments) or (exp.last.length-1 != DIALOG_ARGS) )
      # $stderr.puts "WARNING: Tried to rewrite #{CONFIRM} with #{exp.last.length-1} arguments instead of #{DIALOG_ARGS}" 
      return nil
    end
    generate_var_assign(DIALOG_VAR,  s(:FunctionCall, 
	s(:DotAccessor, s(:NewExpr, s(:Resolve, DIALOG)), CONFIRM_ACCESSOR),
	s(:Arguments, s(:String, "'#{DIALOG_TITLE}'"), exp.pop) 
    ) )
  end

  def generate_alert(exp)
    if(not type?(exp.last, :Arguments) or (exp.last.length-1 != DIALOG_ARGS) )
      # $stderr.puts "WARNING: Tried to rewrite #{ALERT} with #{exp.last.length-1} arguments instead of #{DIALOG_ARGS}" 
      return nil
    end
    generate_var_assign(DIALOG_VAR,  s(:FunctionCall, 
	s(:DotAccessor, s(:NewExpr, s(:Resolve, DIALOG)), ALERT_ACCESSOR),
	s(:Arguments, s(:String, "'#{DIALOG_TITLE}'"), exp.pop) 
    ) )
  end

  # var.event = function() { exp }
  def generate_event(exp, var, event)
    s(:ExpressionStatement, s(:OpEqual, s(:DotAccessor, s(:Resolve, var), event),
		s(:FunctionExpr, FUNCTION, nil , s(:FunctionBody, exp)))
    )
  end

  # object.getAccessor(), object.setAccessor(args)
  def generate_etter(object, accessor, args, set_or_get=SET)
    s(:FunctionCall, s(:DotAccessor, object, etter(accessor, set_or_get) ), args )
  end
  def generate_setter(o, accessor, args); generate_etter(o, accessor, args, SET); end
  def generate_getter(o, accessor); generate_etter(o, accessor, s(:Arguments), GET); end
  def generate_get_style(o, arg); generate_etter(o, STYLE, s(:Arguments, s(:String, "'#{arg}'")), GET); end

  # var name = ...;
  def generate_var_assign(name, exp); s(:VarStatement, s(:VarDecl, name, s(:AssignExpr, exp))); end

  # For <input> tags
  # -> __obj.getForm().submit();
  def generate_confirm_form_callback
    s(:ExpressionStatement, s(:FunctionCall, s(:DotAccessor, s(:DotAccessor, s(:Resolve, THIS_VAR), 'form'), 'submit'), s(:Arguments)))
  end

  # For <a> tags
  # -> document.setLocation(__obj.getHref());
  def generate_confirm_link_callback
    s(:ExpressionStatement, s(:OpEqual, s(:DotAccessor, s(:Resolve, 'document'), 'location'), s(:DotAccessor, s(:Resolve, THIS_VAR)  , 'href') ))
  end
  ############################################################
  # Utility Methods: 

  def CONFIRM_EXP(); s(:ExpressionStatement, s(:FunctionCall, s(:Resolve, CONFIRM), ANY())); end
  def ALERT_EXP(); s(:ExpressionStatement, s(:FunctionCall, s(:Resolve, ALERT), ANY())); end
  def BANNED_EXTEND_DOT(); s(:DotAccessor, s(:Resolve, ONE_OF(BANNED_EXTENDORS)), PROTOTYPE); end
  def BANNED_OBJECT_DOT(); s(:DotAccessor, s(:Resolve, ONE_OF(BANNED_OBJECTS)), ANY()); end
  def AMBIGUOUS_DOT(); s(:DotAccessor, ANY(), ONE_OF(AMBIGUOUS.keys)); end
  def STYLE_DOT(); s(:DotAccessor, s(:DotAccessor, ANY(), STYLE), ANY()); end
  def GETTER_DOT(); s(:DotAccessor, ANY(), ONE_OF(GETTERS)); end
  def SET_ATTRIBUTE_CALL(); s(:FunctionCall, s(:DotAccessor, ANY(), SET_ATTR), ANY()); end
  def SET_OP_EQUAL(); s(:OpEqual, s(:DotAccessor, ANY(), ONE_OF(SETTERS)), ANY()); end
  def SPECIAL_OP_EQUAL(); s(:OpEqual, s(:DotAccessor, ANY(), ONE_OF(SPECIAL_SETTERS.keys)), ANY()); end
  def STYLE_OP_EQUAL(); s(:OpEqual, STYLE_DOT(), ANY()); end
  def CONFIRM_CALL(); s(:FunctionCall, s(:Resolve, CONFIRM), ANY()); end
  def CONFIRM_IF_ELSE(); s(:If, CONFIRM_CALL(), ANY(), ANY()); end
  def CONFIRM_IF(); s(:If, CONFIRM_CALL(), ANY()); end
  def CONFIRM_RETURN(); s(:Return, CONFIRM_CALL()); end

  # change attribute to getter or setter 
  def etter(attribute, set_or_get=SET)
    attribute = attribute[0,1].upcase + attribute[1,attribute.length] if(set_or_get)
    "#{set_or_get}#{attribute}"
  end

  def type?(list, typ)
    (Array === list) && (list.first == typ)
  end
end

end
