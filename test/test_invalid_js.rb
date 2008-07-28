class InvalidJsTest < Test::Unit::TestCase
  def test_unbalanced_paren
    assert_raises(ParseError) { assert_fbjs("hello(;") }
  end

  def test_unbalanced_curly
    assert_raises(ParseError) { assert_fbjs("a = function() {;") }
  end

  def test_unbalanced_brace
    assert_raises(ParseError) { assert_fbjs('var foo = [1);') }
  end

  def test_unknown_getter_setter_property
    assert_raises(ParseError) { assert_fbjs("var foo = { gt a() { } };") }
  end

  def test_unknown_getter_setter_property_with_params
    assert_raises(ParseError) { assert_fbjs("var foo = { se a(b) { } };") }
  end

  def test_weird_bitwise_not
    assert_raises(ParseError) { assert_fbjs('~~10;') }
  end

  def test_weird_logical_not
    assert_raises(ParseError) { assert_fbjs('!.foo;') }
  end

  def test_weird_unary_minus
    assert_raises(ParseError) { assert_fbjs('-_0;') }
  end

  def test_weird_type_of
    assert_raises(ParseError) { assert_fbjs('typeof ++;') }
  end

  def test_weird_unary_plus
    assert_raises(ParseError) { assert_fbjs('+!10;') }
  end

  def test_invalid_boolean_in_while
    assert_raises(ParseError) { assert_fbjs("while(+) { foo(); }") }
  end

  def test_invalid_boolean_in_switch
    assert_raises(ParseError) { assert_fbjs("switch(_) { }") }
  end

  def test_invalid_in_switch_case
    assert_raises(ParseError) { assert_fbjs("switch(a) {
         		          case &:
                    			foo();
		                   break;
			    }") }
  end

  def test_invalid_boolean_in_do_while
    assert_raises(ParseError) { assert_fbjs("do { foo(); } while(@);") }
  end

  def test_invalid_value_in_with
    assert_raises(ParseError) { assert_fbjs("with(~) { foo(); }") }
  end

  def test_invalid_const_statement
    assert_raises(ParseError) { assert_fbjs("const + foo;") }
  end

  def test_invalid_label
    assert_raises(ParseError) { assert_fbjs("foo:: var foo;") }
  end

  def test_invalid_object_literal
    assert_raises(ParseError) { assert_fbjs("var foo = { ^ };") }
  end

  def test_invalid_property
    assert_raises(ParseError) { assert_fbjs("var foo = { {bar: 10} };") }
  end

  def test_invalid_bracket_access
    assert_raises(ParseError) { assert_fbjs("var foo = foo.bar[[10]];") }
  end

  def test_invalid_new_exprs
    assert_raises(ParseError) { assert_fbjs("var foo = new + Array();") }
    assert_raises(ParseError) { assert_fbjs("var foo = new Array(());") }
    assert_raises(ParseError) { assert_fbjs("var foo = new Array(a w 10);") }
  end

  def test_invalid_try_finally
    assert_raises(ParseError) { assert_fbjs('try { var x = 10; } hey! finally { var x = 20; }') }
  end

  def test_invalid_try_catch
    assert_raises(ParseError) { assert_fbjs('try { var x = 10; } catch(a)() { var x = 20; }') }
  end

  def test_invalid_comma
    assert_raises(ParseError) { assert_fbjs('i = 10,, j = 11;') }
  end

  def test_invalid_in
    assert_raises(ParseError) { assert_fbjs('var x = 0 in % foo;') }
  end

  def test_invalid_ifs
    assert_raises(ParseError) { assert_fbjs('if(5 && 10*) var foo = 20;') }
    assert_raises(ParseError) { assert_fbjs('if(5 && 10) ho { var foo = 20; }') }
    assert_raises(ParseError) { assert_fbjs('if(5 && 10) { var foo = 20; } maybe else var foo = 10;') }
    assert_raises(ParseError) { assert_fbjs('if(5 && 10) { var foo = 20; } else so { var foo = 10; }') }
  end

  def test_invalid_conditional
    assert_raises(ParseError) { assert_fbjs('var x = 5 <> 10 ? 20 : 30;') }
  end

  def test_invalid_for_in
    assert_raises(ParseError) { assert_fbjs('forfor(foo in bar) { var x = 10; }') }
  end
end
