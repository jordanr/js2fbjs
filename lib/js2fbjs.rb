require 'fbjs_rewriter'
require 'rkelly'

# To hook up to Facebooker, init.rb sends this module 
# as an include into the Facebooker::Rails::Controller.
# It calls the regular render and then afterwards,
# tries to translate JavaScript inside fbml tags.
module Js2Fbjs
  ONS = Regexp.new("onclick|onsubmit") # add more

  # Translates js event calls into fbjs
  # If you pass in :without_js2fbjs or are on a non-canvas
  # page, it won't translate your js.
  def render(*args)
    no_thanks = args.delete(:without_js2fbjs)
    if !request_is_for_a_facebook_canvas? || no_thanks
      super
    else
      super
      response.body, errors = translate_fbml(response.body)
      errors.each { |err| $stderr.puts err }
    end
  end

  def translate_fbml(fbml)
      errors = []
      dbl_quote_matches = fbml.scan(/<([a-zA-Z]+)([^>]*#{ONS}=)(")([^">]*)(")([^>]*)>/)
      sing_quote_matches= fbml.scan(/<([a-zA-Z]+)([^>]*#{ONS}=)(')([^'>]*)(')([^>]*)>/)
      (dbl_quote_matches+sing_quote_matches).each { |match|
 	next if(match.first.nil?) # hmm, break probably too, meaning no javascript on page
  	begin 
	  js = FbjsRewriter.translate(match[3], match[0]) # js, tag
	rescue
	  errors.push("warning: translation failed for \"#{match[3]}\" inside \"#{match[0]}\" tag, #{$!}")
	  next;
	end
	pattern = Regexp.new(Regexp.escape("<"+match.join+">"))
	# we standardize single quoted to double quoted bcuz fbjs_rewriter single quotes strings
	repl = "<"+match[0]+match[1]+"\""+js.gsub(/"/,"\'")+"\""+match[5]+">"
        fbml.gsub!(pattern, repl)
      } 
      return fbml, errors
  end
end
