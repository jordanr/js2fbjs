require File.dirname(__FILE__) + '/test_helper.rb'

class CompatableJsTest < Test::Unit::TestCase
  #  inherited processing tests
  def test_anonymous_function_expr
    assert_fbjs('a = function() { };')
  end

  def test_anonymous_function_expr_with_args
    assert_fbjs('a = function(a, b, c) { };')
  end

  def test_this_node
    assert_fbjs('this.foo;')
  end

  def test_bitwise_not_node
    assert_fbjs('~10;')
  end

  def test_delete_node
    assert_fbjs('delete foo;')
  end

  def test_element_node
    assert_fbjs('var foo = [1];')
  end

  def test_logical_not_node
    assert_fbjs('!foo;')
  end

  def test_unary_minus_node
    assert_fbjs('-0;')
  end

  def test_return_node
    assert_fbjs('return foo;')
    assert_fbjs('return;')
  end

  def test_throw_node
    assert_fbjs('throw foo;')
  end

  def test_type_of_node
    assert_fbjs('typeof foo;')
  end

  def test_unary_plus_node
    assert_fbjs('+10;')
  end

  def test_void_node
    assert_fbjs('void(0);')
  end

  [
    [:add, '+'],
    [:and_equal, '&='],
    [:bit_and, '&'],
    [:bit_or, '|'],
    [:bit_xor, '^'],
    [:divide, '/'],
    [:divide_equal, '/='],
    [:equal_equal, '=='],
    [:greater, '>'],
    [:greater_or_equal, '>='],
    [:left_shift, '<<'],
    [:left_shift_equal, '<<='],
    [:less_or_equal, '<='],
    [:logical_and, '&&'],
    [:logical_or, '||'],
    [:minus_equal, '-='],
    [:mod, '%'],
    [:mod_equal, '%='],
    [:multiply, '*'],
    [:multiply_equal, '*='],
    [:not_equal, '!='],
    [:not_strict_equal, '!=='],
    [:or_equal, '|='],
    [:plus_equal, '+='],
    [:right_shift, '>>'],
    [:right_shift_equal, '>>='],
    [:strict_equal, '==='],
    [:subtract, '-'],
    [:ur_shift, '>>>'],
    [:uright_shift_equal, '>>>='],
    [:xor_equal, '^='],
    [:instanceof, 'instanceof'],
  ].each do |name, value|
    define_method(:"test_#{name}_node") do
      assert_fbjs("10 #{value} 20;")
    end
  end

  def test_while_node
    assert_fbjs("while(true) { foo(); }")
  end

  def test_switch_node
    assert_fbjs("switch(a) { }")
  end

  def test_switch_case_node
    assert_fbjs("switch(a) {
                   case 1:
                    foo();
                   break;
    }")
  end

  def test_do_while_node
    assert_fbjs("do { foo(); } while(true);")
  end

  def test_with_node
    assert_fbjs("with(o) { foo(); }")
  end

  def test_const_statement_node
    assert_fbjs("const foo;")
  end

  def test_label_node
    assert_fbjs("foo: var foo;")
  end

  def test_object_literal
    assert_fbjs("var foo = { };")
  end

  def test_property
    assert_fbjs("var foo = { bar: 10 };")
  end

  def test_getter_node
    assert_fbjs("var foo = { get a() { } };")
  end

  def test_setter_node
    assert_fbjs("var foo = { set a(b) { } };")
  end

  def test_bracket_access_node
    assert_fbjs("var foo = foo.bar[10];")
  end

  def test_new_expr_node
    assert_fbjs("var foo = new Array();")
    assert_fbjs("var foo = new Array(10);")
    assert_fbjs("var foo = new Array(a, 10);")
  end

  def test_try_finally
    assert_fbjs('try { var x = 10; } finally { var x = 20; }')
  end

  def test_try_catch
    assert_fbjs('try { var x = 10; } catch(a) { var x = 20; }')
  end

  def test_comma_node
    assert_fbjs('i = 10, j = 11;')
  end

  def test_in_node
    assert_fbjs('var x = 0 in foo;')
  end

  def test_if_node
    assert_fbjs('if(5 && 10) var foo = 20;')
    assert_fbjs('if(5 && 10) { var foo = 20; }')
    assert_fbjs('if(5 && 10) { var foo = 20; } else var foo = 10;')
    assert_fbjs('if(5 && 10) { var foo = 20; } else { var foo = 10; }')
  end

  def test_conditional_node
    assert_fbjs('var x = 5 < 10 ? 20 : 30;')
  end

  def test_for_in_node
    assert_fbjs('for(foo in bar) { var x = 10; }')
  end
end
