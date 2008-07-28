require 'js2fbjs/rails/controller'

module ::ActionController
  class Base
    def self.inherited_with_js2fbjs(subclass)
      inherited_without_js2fbjs(subclass)
      if subclass.to_s == "ApplicationController"
        subclass.send(:include,Js2Fbjs::Rails::Controller)
      end
    end
    class << self
      alias_method_chain :inherited, :js2fbjs
    end
  end
end

