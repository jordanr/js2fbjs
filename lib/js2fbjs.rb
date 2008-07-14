#!/usr/bin/env ruby -w

begin require 'rubygems'; rescue LoadError; end
require 'sexp_processor'

class Js2Fbjs < SexpProcessor

  def self.translate(str)
    require 'rkelly'
    self.new.process(RKelly::Parser.new.parse(str).to_sexp)
  end

  def initialize
    super
    @indent = "  "
    self.auto_shift_type = true
    self.strict = true
    self.expected = String
  end

  def process exp
    exp = Sexp.from_array(exp) if Array === exp unless Sexp === exp
    puts exp.to_s
    super exp
  end

  ############################################################
  # Processors  
  PROCESSORS = %w{
        add and args array assign
        bit_and bit_or bit_xor bitwise_not block bracket_access break
        case case_block comma conditional const const_decl continue
        delete divide do_while dot_access element empty equal expression
        false for for_in func_body func_decl func_expr function_call
        getter greater greater_or_equal if in instance_of
        label less less_or_equal lit lshift modulus multiply
        new_expr nil not not_equal not_strict_equal
        object op_and_equal op_equal op_divide_equal op_lshift_equal op_minus_equal op_mod_equal
        op_multiply_equal op_or_equal op_plus_equal op_rshift_equal op_urshift_equal op_xor_equal or
        param postfix prefix property resolve return rshift
        setter str strict_equal subtract switch this throw true try typeof
        u_minus u_plus urshift var var_decl void while with
  }
      [ 
        [:add, '+'],
        [:and, '&&'],
        [:bit_and, '&'],
        [:bit_or, '|'],
        [:bit_xor, '^'],
        [:divide, '/'],
        [:equal, '=='],
        [:greater, '>'],
        [:greater_or_equal, '>='],
        [:in, 'in'],
        [:instance_of, 'instanceof'],
        [:less, '<'],
        [:less_or_equal, '<='],
        [:lshift, '<<'],
        [:modulus, '%'],
        [:multiply, '*'],
        [:not_equal, '!='],
        [:not_strict_equal, '!=='],
        [:op_and_equal, '&='],
        [:op_divide_equal, '/='],
        [:op_lshift_equal, '<<='],
        [:op_minus_equal, '-='],
        [:op_mod_equal, '%='],
        [:op_multiply_equal, '*='],
        [:op_or_equal, '|='],
        [:op_plus_equal, '+='],
        [:op_rshift_equal, '>>='],
        [:op_urshift_equal, '>>>='],
        [:op_xor_equal, '^='],
        [:or, '||'],
        [:rshift, '>>'],
        [:strict_equal, '==='],
        [:subtract, '-'],
        [:urshift, '>>>'],
      ].each do |name,op|
        define_method(:"process_#{name}") do |exp|
          "#{op}"
        end
      end

  def process_args(exp)
  end
  def process_array(exp)
  end
  def process_assign(exp)
  end
  def process_bitwise_not(exp)
  end
  def process_block(exp)
  end
  def process_bracket_access(exp)
  end
  def process_break(exp)
  end
  def process_case(exp)
  end
  def process_case_block(exp)
  end
  def process_comma(exp)
  end
  def process_conditional(exp)
  end
  def process_const(exp)
  end
  def process_const_decl(exp)
  end
  def process_continue(exp)
  end
  def process_delete(exp)
  end
  def process_do_while(exp)
  end
  def process_dot_access(exp)
  end
  def process_element(exp)
  end
  def process_empty(exp)
  end
  def process_expression(exp)
  end
  def process_false(exp)
  end
  def process_for(exp)
  end
  def process_for_in(exp)
  end
  def process_func_body(exp)
  end
  def process_func_decl(exp)
  end
  def process_func_expr(exp)
  end
  def process_function_call(exp)
  end
  def process_getter(exp)
  end
  def process_greater(exp)
  end
  def process_greater_or_equal(exp)
  end
  def process_if(exp)
	p exp.sexp_body
	"if(#{process(exp.shift)})"
  end
  def process_label(exp)
  end
  def process_lit(exp)
  end
  def process_new_expr(exp)
  end
  def process_nil(exp)
  end
  def process_not(exp)
  end
  def process_object(exp)
  end
  def process_op_equal(exp)
  end
  def process_param(exp)
  end
  def process_postfix(exp)
  end
  def process_prefix(exp)
  end
  def process_property(exp)
  end
  def process_resolve(exp)
  end
  def process_return(exp)
  end
  def process_setter(exp)
  end
  def process_str(exp)
  end
  def process_switch(exp)
  end
  def process_this(exp)
  end
  def process_throw(exp)
  end
  def process_true(exp)
  end
  def process_try(exp)
  end
  def process_typeof(exp)
  end
  def process_u_minus(exp)
  end
  def process_u_plus(exp)
  end
  def process_urshift(exp)
  end
  def process_var(exp)
  end
  def process_var_decl(exp)
  end
  def process_void(exp)
  end
  def process_while(exp)
  end
  def process_with(exp)
  end
  ############################################################
  # Rewriters:

  ############################################################
  # Utility Methods:

  def indent(s)
    s.to_s.split(/\n/).map{|line| @indent + line}.join("\n")
  end
end
