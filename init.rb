require 'facebooker'
require 'js2fbjs'

Facebooker::Rails::Controller.send(:include, Js2Fbjs)

