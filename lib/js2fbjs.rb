require 'fbjs_rewriter'
require 'rkelly'

module Js2Fbjs
  ONS = Regexp.new("onclick|onsubmit")
  CONFIRM_NOW = Regexp.new("return confirm|confirm")

  # Translates js event calls into fbjs
  def render(*args)
    super
    if request_is_for_a_facebook_canvas?
      matches = response.body.scan(/<([a-zA-Z]+)[^>]*#{ONS}="([^">]*)".*>/).compact
      matches.each { |match|
        response.body.gsub!(Regexp.new(Regexp.escape(match.last)), FbjsRewriter.translate(match.pop, match.pop)) unless match.first.nil?
      } 
    end
  end
end
