require File.dirname(__FILE__) + '/test_helper.rb'

class ErrorRaisingJsTest < Test::Unit::TestCase
  def test_raises_extend_base_object
    assert_raises(Js2Fbjs::FbjsRewriter::BannedExtendError) { Js2Fbjs::FbjsRewriter.translate("Window.prototype") }
  end

  def test_raises_ambiguous_accessor
    assert_raises(Js2Fbjs::FbjsRewriter::AmbiguousAccessorError) { 
	Js2Fbjs::FbjsRewriter.translate("this.innerHtml = 'doesnotmatte';") 

    }
  end
  def test_raises_ambiguous_accessor2
    assert_raises(Js2Fbjs::FbjsRewriter::AmbiguousAccessorError) { 
	Js2Fbjs::FbjsRewriter.translate("a.innerHtml = 'what';") 
    }
  end
end
