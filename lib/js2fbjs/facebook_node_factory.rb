require 'js2fbjs/conversions'
require 'rkelly/nodes'
module Js2fbjs
  class FacebookNodeFactory
    include Conversions

    def self.produce(o)
	product = case(o)
	  when RKelly::Nodes::OpEqualNode:
		puts "eq"
		produce_from_op_equal_node(o)
	  when RKelly::Nodes::DotAccessorNode:
		puts "dot"
		produce_from_dot_accessor_node(o)		
	  when RKelly::Nodes::FunctionCallNode:
		puts "fun"
		produce_from_function_call_node(o)
	  else
		puts "else"
		o
	end
	product
    end

    private 

    def self.produce_from_op_equal_node(o)
	if(setter?(o.left))
	  RKelly::Nodes::FunctionCallNode.new(produce_setter(o.left), o.value)
	elsif(dot?(o.left) && style?(o.left.value) )
	  RKelly::Nodes::FunctionCallNode.new(produce_style(o.left.value),produce_arguments([produce_string(o.left.accessor),o.value]) )
	else
	  o
	end
    end
    def self.produce_from_function_call_node(o)
	puts o.arguments
	if(set_attribute?(o.value))
          if(o.arguments.value.length != 2)
            puts "Warning: tried to convert invalid setAttribute.  Should have 2 arguments but has #{o.arguments.value.length}"
	    o
	  else
            attribute = o.arguments.value.shift.value
            attribute.gsub!(/'([a-z]+)'/,'\1')
	    RKelly::Nodes::FunctionCallNode.new(produce_set_attribute(o.value, attribute), o.arguments)
	  end 
	else
	  o
	end
    end
    def self.produce_from_dot_accessor_node(o)
	if(getter?(o))
	  RKelly::Nodes::FunctionCallNode.new(produce_getter(o), RKelly::Nodes::ArgumentsNode.new([]) )
	else
	  o
	end
    end

    def self.produce_arguments(args)
          RKelly::Nodes::ArgumentsNode.new(args)
    end
    def self.produce_string(value)
          RKelly::Nodes::StringNode.new("'#{value}'")
    end

    def self.produce_dot_accessor(value,accessor, prefix='set')
          RKelly::Nodes::DotAccessorNode.new(value,"#{prefix}#{accessor[0,1].upcase}#{accessor[1,accessor.length]}")
    end

    def self.produce_getter(dot)
	  produce_dot_accessor(dot.value, dot.accessor, 'get')
    end
    def self.produce_setter(dot)
	  produce_dot_accessor(dot.value, dot.accessor)
    end
    def self.produce_set_attribute(dot, attribute)
	  produce_dot_accessor(dot.value, attribute)
    end
    def self.produce_style(dot)
	  produce_dot_accessor(dot.value, 'style')
    end

    def self.dot?(dot)
        dot.is_a?(RKelly::Nodes::DotAccessorNode)
    end
    def self.getter?(dot)
	dot?(dot) && GETTERS.include?(dot.accessor)
    end

    def self.setter?(dot)
	dot?(dot) && SETTERS.include?(dot.accessor)
    end
    def self.style?(dot)
	dot?(dot) && dot.accessor == 'style'
    end

    def self.set_attribute?(dot)
	dot?(dot) && dot.accessor == 'setAttribute'
    end

  end
end
