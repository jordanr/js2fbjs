require 'test/unit'
require 'js2fbjs'

class Test::Unit::TestCase
  def assert_fbjs(expected, actual = nil)
    fbjs = FbjsRewriter.translate(actual || expected)
    fbjs = fbjs.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    expected = expected.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    assert_equal(expected, fbjs)
  end

  def assert_js(expected, actual = nil)
    js = JsProcessor.translate(actual || expected)
    js = js.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    expected = expected.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    assert_equal(expected, js)
  end
end
