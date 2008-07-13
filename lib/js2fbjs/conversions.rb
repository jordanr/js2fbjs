# <em>See</em> http://wiki.developers.facebook.com/index.php/FBJS
module Js2fbjs
  module Conversions
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

    # style => getWidth, setWidth, getColor, setColor, ...
    # setAttribute => setName, setValue, ...
    # innerText, textContent => setTextValue
    # innerHtml	=> setInnerFBML, setInnerXHTML
    SPECIALS = %w{
	style setAttribute innerText textContent innerHtml
    }

    # ? => getAbsoluteTop getAbsoluteLeft
    # ? => getRootElement
    UNKNOWNS = %w{
    }
  end
end
