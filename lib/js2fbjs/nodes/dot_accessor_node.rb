module RKelly
  module Nodes
    class DotAccessorNode < Node
      def == (other)
	(value==other.value) && (accessor == other.accessor)
      end
    end
  end
end
