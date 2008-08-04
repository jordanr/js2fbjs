require 'test/unit'
require 'rubygems'

$: << File.join(File.dirname(__FILE__), '..', 'lib')
RAILS_ROOT=File.join(File.dirname(__FILE__),'..','..')
require 'js2fbjs'

class Test::Unit::TestCase
  def assert_fbjs(expected, actual = nil, tag = nil, strict = false)
    fbjs = Js2Fbjs::FbjsRewriter.translate(actual || expected, tag, strict)
    fbjs = fbjs.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    expected = expected.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    assert_equal(expected, fbjs)
  end

  def assert_strict_fbjs(expected)
    assert_fbjs(expected, nil, nil, true)
  end

  def assert_js(expected, actual = nil)
    js = Js2Fbjs::JsProcessor.translate(actual || expected)
    js = js.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    expected = expected.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    assert_equal(expected, js)
  end
end
