module RKelly
  module Visitors
    class SexpVisitor < Visitor
      TERMINAL_NODES.each do |type|
        define_method(:"visit_#{type}Node") do |o|
          [type.to_sym, o.value]
        end
      end

      (BINARY_NODES+ARRAY_VALUE_NODES+CONDITIONAL_NODES+
	FUNC_CALL_NODES+FUNC_DECL_NODES+
	%w{For ForIn Try BracketAccessor}).each do |type|
        define_method(:"visit_#{type}Node") do |o|
          [type.to_sym, *super]
        end
      end

      # could be nil super
      NAME_VALUE_NODES.each do |type|
        define_method(:"visit_#{type}Node") do |o|
          [type.to_sym, o.name, super]
        end
      end

      SINGLE_VALUE_NODES.each do |type|
        define_method(:"visit_#{type}Node") do |o|
          [type.to_sym, super]
        end
      end


      PREFIX_POSTFIX_NODES.each do |type|
        define_method(:"visit_#{type}Node") do |o|
          [type.to_sym, super, o.value]
        end
      end

      # Should be done in super?
      def visit_DotAccessorNode(o)
        [:DotAccessor, super, o.accessor]
      end
    end
  end
end
