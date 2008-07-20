class FbjsRewriterTest < Test::Unit::TestCase
  CONFIRM_DIALOG = "var __dlg = new Dialog().showChoice('The page says:', 'Are you sure?');"
  THIS_ASSIGN = "var __obj = this;"
  FORM_CONFIRM = "__dlg.onconfirm = function() { __obj.getForm().submit(); };"
  LINK_CONFIRM = "__dlg.onconfirm = function() { document.setLocation(__obj.getHref()); };"

  # rewriting tests
  def test_raises_error
    assert_raises(SexpProcessorError) { assert_fbjs("var __obj = this;var __dlg = new Dialog().showChoice(") }
  end

  FbjsRewriter::GETTERS.each do |getter|
    define_method(:"test_get_for_#{getter}") do
      assert_fbjs("this.get#{getter[0,1].upcase+getter[1,getter.length]}();", "this.#{getter};")
    end
  end
  FbjsRewriter::SETTERS.each do |setter|
    define_method(:"test_set_for_#{setter}") do
      assert_fbjs("this.set#{setter[0,1].upcase+setter[1,setter.length]}('blue crabs');", "this.#{setter} = 'blue crabs';")
    end
  end

  def test_set_attribute
    assert_fbjs("a.setMethod('delete');", "a.setAttribute('method', 'delete');")
    assert_fbjs("a.setMethod(b.getMethod());", "a.setAttribute('method', b.method);")
  end

  def test_set_attribute_with_too_many_args
    assert_fbjs("a.setAttribute('method', 'delete', 'maybe');")
  end

  def test_set_style
    assert_fbjs("a.setStyle('width', '320px');", "a.style.width = '320px';")
    assert_fbjs("a.setStyle('width', b.getMethod());", "a.style.width = b.method;")
  end
  def test_get_style
    assert_fbjs("a.getStyle('width');", "a.style.width;")
  end

  def test_confirm_expression
    assert_fbjs(CONFIRM_DIALOG, "confirm('Are you sure?');")
  end

  def test_confirm_expression_with_too_many_args
    assert_fbjs("confirm('Are you sure?', 'really?');")
  end

  def test_confirm_return
    assert_fbjs("#{CONFIRM_DIALOG}return false;", "return confirm('Are you sure?');")
  end

  def test_confirm_return_in_form
    assert_fbjs("#{THIS_ASSIGN}#{CONFIRM_DIALOG}#{FORM_CONFIRM}return false;", "return confirm('Are you sure?');", 'input')
  end

  def test_confirm_return_in_link
    assert_fbjs("#{THIS_ASSIGN}#{CONFIRM_DIALOG}#{LINK_CONFIRM}return false;", "return confirm('Are you sure?');", 'a')
  end

  def test_confirm_return_with_too_many_args
    assert_fbjs("return confirm('Are you sure?', 'yes?');")
  end

  def test_if_confirm_without_block
    assert_fbjs("var __obj = this;#{CONFIRM_DIALOG}__dlg.onconfirm = function() { do_something(); };", "if(confirm('Are you sure?')) do_something();")
  end

  def test_if_confirm_with_block
    assert_fbjs("var __obj = this;#{CONFIRM_DIALOG}__dlg.onconfirm = function() { do_something(); };", "if(confirm('Are you sure?')) { do_something(); }")
  end

  def test_if_confirm_with_too_many_args
    assert_fbjs("if(confirm('Are you sure?', 'hmm?')) do_something();")
  end

  def test_if_else_confirm_without_blocks
    assert_fbjs("var __obj = this;#{CONFIRM_DIALOG}__dlg.onconfirm = function() { do_something(); };__dlg.oncancel = function() { do_something_else(); };", 
		"if(confirm('Are you sure?')) do_something(); 
		else do_something_else();")
  end

  def test_if_else_confirm_with_blocks
    assert_fbjs("var __obj = this;#{CONFIRM_DIALOG}__dlg.onconfirm = function() { do_something(); };__dlg.oncancel = function() { do_something_else(); };",
		"if(confirm('Are you sure?')) { 
		  do_something(); 
		}
		else {
		  do_something_else();
		}")
  end

  def test_if_else_confirm_with_too_many_args
    assert_fbjs("if(confirm('Are you sure?', 'hmmm?')) do_something(); 
		else do_something_else();")
  end

  def test_if_confirm_with_thises_to_sub
    assert_fbjs("var __obj = this;#{CONFIRM_DIALOG}__dlg.onconfirm = function() { 
		a = __obj.hello;
		__obj.world = '!!';
		do_something(); };", 
	"if(confirm('Are you sure?')) { 
		a = this.hello;
		this.world = '!!';
		do_something(); 
	}")

  end
  def test_if_else_confirm_with_thises_to_sub
    assert_fbjs("var __obj = this;#{CONFIRM_DIALOG}__dlg.onconfirm = function() { 
		a = __obj.hello;
		__obj.world = '!!';
		do_something(); };__dlg.oncancel = function() {
		  b = __obj.hello;
		};", 
	"if(confirm('Are you sure?')) { 
		a = this.hello;
		this.world = '!!';
		do_something(); 
	}
	else {
		b = this.hello;
	}")
  end

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
