#!/usr/bin/env ruby -w

#begin require 'rubygems'; rescue LoadError; end
require 'js_processor'

class FbjsProcessor < JsProcessor

  def process exp
    exp = Sexp.from_array(exp) if Array === exp unless Sexp === exp
    super exp
  end

  ############################################################
  # Processors  

  ############################################################
  # Rewriters:
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


  def rewrite_OpEqual(exp)
    p "op"
    p exp
    if(SETTERS.include?(exp[1].last))
      exp.shift # get rid of type
      s(:FunctionCall, s(exp.first.shift, exp.first.shift, etter(exp.first.shift) ), exp.shift )
    else
      exp	
    end
  end
  def rewrite_DotAccessor(exp)
    p "dot==="
    p exp
    if(GETTERS.include?(exp.last))
      s(:FunctionCall, s(exp.shift, exp.shift, etter(exp.shift, 'get') ) )
    else
      exp
    end
  end	


  def process_FunctionCall(exp)
	super
  end

  ############################################################
  # Utility Methods: 
  private

  # change attribute to getter or setter 
  def etter(attribute, set_or_get='set')
    attribute = attribute[0,1].upcase + attribute[1,attribute.length] if(set_or_get)
    "#{set_or_get}#{attribute}"
  end
end

