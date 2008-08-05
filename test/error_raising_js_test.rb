require File.dirname(__FILE__) + '/test_helper.rb'

class ErrorRaisingJsTest < Test::Unit::TestCase
  def test_raises_extend_base_object
    assert_raises(Js2Fbjs::FbjsRewriter::BannedExtendError) { Js2Fbjs::FbjsRewriter.translate("Window.prototype") }
  end
end
