require File.dirname(__FILE__) + "/helper"

class DivideNodeTest < NodeTestCase
  def test_to_sexp
    node = DivideNode.new(NumberNode.new(5), NumberNode.new(10))
    assert_sexp([:divide, [:lit, 5], [:lit, 10]], node)
  end
end
