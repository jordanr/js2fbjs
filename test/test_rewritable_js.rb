class RewritableJsTest < Test::Unit::TestCase
  CONFIRM_DIALOG = "var __dlg = new Dialog().showChoice('The page says:', 'Are you sure?');"
  THIS_ASSIGN = "var __obj = this;"
  FORM_CONFIRM = "__dlg.onconfirm = function() { __obj.getForm().submit(); };"
  LINK_CONFIRM = "__dlg.onconfirm = function() { document.setLocation(__obj.getHref()); };"

  # rewriting tests

  Js2Fbjs::FbjsRewriter::GETTERS.each do |getter|
    define_method(:"test_get_for_#{getter}") do
      assert_fbjs("this.get#{getter[0,1].upcase+getter[1,getter.length]}();", "this.#{getter};")
    end
  end
  Js2Fbjs::FbjsRewriter::SETTERS.each do |setter|
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
end
