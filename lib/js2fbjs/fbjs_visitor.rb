require 'js2fbjs/facebook_node_factory'
module Js2fbjs
    class FbjsVisitor < RKelly::Visitors::ECMAVisitor
      SUSPECT_NODES = %w{
	OpEqual FunctionCall DotAccessor
      }

      SUSPECT_NODES.each do |type|
        define_method(:"visit_#{type}Node") do |o|
  	  o2 = FacebookNodeFactory.produce(o)
	  (o == o2) ? super : o2.accept(self)
        end
      end
  end
end
