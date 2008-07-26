require 'fbjs_rewriter'
require 'rkelly'

# To hook up to Facebooker, init.rb sends this module 
# as an include into the Facebooker::Rails::Controller.
# It calls the regular render and then afterwards,
# tries to translate JavaScript inside fbml tags.
module Js2Fbjs
  def self.included(controller)
    controller.extend(ClassMethods)
#    controller.after_filter :translate_js_into_fbjs
  end

  private
  ONS = Regexp.new("onclick|onsubmit") # add more

  def translate_js_to_fbjs
      if request_is_for_a_facebook_canvas?
        response.body, errors = translate_fbml(response.body)
        errors.each { |err| logger.warning "#{err}" }
      end
  end

  # really needs some refactoring
  def translate_fbml(fbml)
      errors = []
      dbl_quote_matches = fbml.scan(/<([a-zA-Z]+)([^>]*#{ONS}\s*=\s*)(")([^">]*)(")([^>]*)>/)
      sing_quote_matches= fbml.scan(/<([a-zA-Z]+)([^>]*#{ONS}\s*=\s*)(')([^'>]*)(')([^>]*)>/)
      (dbl_quote_matches+sing_quote_matches).each { |match|
 	next if(match.first.nil?) # hmm, break probably too, meaning no javascript on page
  	begin 
	  js = FbjsRewriter.translate(match[3], match[0]) # js, tag
	rescue
	  errors.push("translation failed for \"#{match[3]}\" inside \"#{match[0]}\" tag, #{$!}")
	  next;
	end
	pattern = Regexp.new(Regexp.escape("<"+match.join+">"))
	# we standardize single quoted to double quoted bcuz fbjs_rewriter single quotes strings
	repl = "<"+match[0]+match[1]+"\""+js.gsub(/"/,"\'")+"\""+match[5]+">"
        fbml.gsub!(pattern, repl)
      } 

      script_tag_matches= fbml.scan(/<script>([^<]*)<\/script>/)
      (script_tag_matches).each { |match|
 	next if(match.first.nil?) # hmm, break probably too, meaning no javascript on page
  	begin 
	  js = FbjsRewriter.translate(match[0]) # all js
	rescue
	  errors.push("translation failed for \"#{match[0]}\" #{$!}")
	  next;
	end
	pattern = Regexp.new(Regexp.escape("<script>#{match[0]}</script>"))
	repl = "<script>#{js}</script>"
        fbml.gsub!(pattern, repl)
      } 

      return fbml, errors
  end
  
  module ClassMethods
    #
    # Creates a filter which translate the response body from javascript to facebook js
    # Accepts the same optional options hash which
    # before_filter and after_filter accept.
    def translate_js_to_fbjs(options = {})
      after_filter :translate_js_to_fbjs, options
    end
  end
end
