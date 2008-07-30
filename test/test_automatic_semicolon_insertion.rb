class AutomaticSemicolonInsertionTest < Test::Unit::TestCase
  def test_basic_statement
    assert_fbjs('return 12;', 'return 12')
  end

  def test_multiline_expression
    assert_fbjs("1 + 1;", "1\n+\n1")
  end

  def test_multiple_statements
    assert_fbjs("var foo; var bar;", "var foo\nvar bar")
  end

  def test_bracketed_statement
    assert_fbjs('{ var foo; }', '{var foo}')
  end

  def test_insertion_before_plus_plus
      assert_fbjs("a = b; ++c;", "a = b\n++c")
  end

  def test_insertion_before_minus_minus
      assert_fbjs("a = b; --c;","a = b\n--c")
  end

  def test_insertion_after_continue
      assert_fbjs("continue; foo;","continue\nfoo")
  end

  def test_insertion_after_break
      assert_fbjs("break; foo;", "break\nfoo")
  end

  def test_insertion_after_return
      assert_fbjs("return; foo;", "return\nfoo")
  end

  def test_insertion_after_throw
    assert_raises(Js2Fbjs::SexpProcessorError) { assert_fbjs("throw\nfoo") }
  end

  def test_no_empty_statement_insertion
    assert_raises(Js2Fbjs::SexpProcessorError) { assert_fbjs("if (a > b)\nelse c = d") }
  end

  def test_no_for_insertion
    assert_raises(Js2Fbjs::SexpProcessorError) { assert_fbjs("for (a;b\n){}") }
  end
end

