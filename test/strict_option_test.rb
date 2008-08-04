require File.dirname(__FILE__) + '/test_helper.rb'
class StrictOptionTest < Test::Unit::TestCase
  include Js2Fbjs::Rails::Controller
  def test_raises
    fbml, errors = translate_fbml("<script>confirm(;</script>", true)
    assert_equal("<script>confirm(;</script>", fbml)
    assert !errors.empty?
  end
end
