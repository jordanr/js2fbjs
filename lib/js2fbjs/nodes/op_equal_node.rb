module Js2fbjs
  module Nodes
    class FacebookOpEqualNode < RKelly::Nodes::OpEqualNode
      include Conversions        
      def setter?
        left.is_a?(RKelly::Nodes::DotAccessorNode) && left.setter?
      end
      def to_setter!
        left.to_setter!
      end
       
      def style?
        left.is_a?(RKelly::Nodes::DotAccessorNode) && left.style?
      end       
    end
  end
end
