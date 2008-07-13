require 'js2fbjs/fbjs_visitor'
module RKelly
  module Nodes
    class Node
      def to_fbjs
        Js2fbjs::FbjsVisitor.new.accept(self)
      end
    end
  end
end

