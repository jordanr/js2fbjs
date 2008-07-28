require 'test/unit'
require 'rubygems'

RAILS_ROOT=File.join(File.dirname(__FILE__),'..','..')
$: << File.join(File.dirname(__FILE__), '..', 'lib')
require 'js2fbjs'

class Test::Unit::TestCase
  def assert_fbjs(expected, actual = nil, tag = nil)
    fbjs = Js2Fbjs::FbjsRewriter.translate(actual || expected, tag)
    fbjs = fbjs.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    expected = expected.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    assert_equal(expected, fbjs)
  end

  def assert_js(expected, actual = nil)
    js = Js2Fbjs::JsProcessor.translate(actual || expected)
    js = js.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    expected = expected.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    assert_equal(expected, js)
  end
end
