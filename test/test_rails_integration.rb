require 'action_controller'
require 'action_controller/test_process'

ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end

class RailsUrlHelperTest < Test::Unit::TestCase
  LABEL = "Test"
  URL = "test.host"
  CONTENT = "r u sure?"
  TITLE = "The page says:"

  class UrlHelperController < ActionController::Base
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TagHelper
    include Js2Fbjs

    def link_to_without
      render :text => self.link_to(LABEL, URL)
    end

    def link_to_with_confirm
      render :text => self.link_to(LABEL, URL, :confirm=>CONTENT)
    end

    def link_to_with_method
     render :text => self.link_to(LABEL, URL, :method=>:delete)
    end

    def link_to_with_confirm_and_method
     render :text => self.link_to(LABEL, URL, :confirm=>CONTENT, :method=>:delete)
    end

    def button_to_without
      render :text => self.button_to(LABEL, URL)
    end

    def button_to_with_confirm
      render :text => self.button_to(LABEL, URL, :confirm=>CONTENT)
    end

    def single_quoted_javascript
      render :text => "<a href=\"#{URL}\" onclick=\'return confirm(\"#{CONTENT}\");\'>#{LABEL}</a>"
    end

    def whitespace_before_quoted_javascript
      render :text => "<a href=\"#{URL}\" onclick = \"return confirm(\'#{CONTENT}\');\">#{LABEL}</a>"
    end

    private
    def rescue_action(e) raise e end 

    def protect_against_forgery?
       false
    end

    def request_is_for_a_facebook_canvas?
      !params['fb_sig_in_canvas'].blank?
    end

  end

  def setup
    @controller = UrlHelperController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_link_to_without_for_canvas
    get :link_to_without, {"fb_sig_in_canvas"=>"1"}
    assert_equal("<a href=\"#{URL}\">#{LABEL}</a>", @response.body)
  end
  def test_link_to_without_for_non_canvas
    get :link_to_without
    assert_equal("<a href=\"#{URL}\">#{LABEL}</a>", @response.body)
  end

  def test_link_to_with_confirm_for_canvas
    get :link_to_with_confirm, {"fb_sig_in_canvas"=>"1"}
    assert_equal( "<a href=\"#{URL}\" onclick=\"var __obj = this;var __dlg = new Dialog().showChoice(\'#{TITLE}\', \'#{CONTENT}\');"+
                 "__dlg.onconfirm = function() { " + 
                 "document.setLocation(__obj.getHref()); };return false;\">#{LABEL}</a>", @response.body)
  end

  def test_link_to_with_confirm_for_non_canvas
    get :link_to_with_confirm
    assert_equal( "<a href=\"#{URL}\" onclick=\"return confirm(\'#{CONTENT}\');\">#{LABEL}</a>", @response.body)
  end

  def test_link_to_with_method_for_canvas
    get :link_to_with_method, {"fb_sig_in_canvas"=>"1"}
    assert_equal( "<a href=\"#{URL}\" onclick=\"var f = document.createElement('form'); f.setStyle('display', 'none'); "+
                 "this.getParentNode().appendChild(f); f.setMethod('POST'); f.setAction(this.getHref()); " +
                 "var m = document.createElement('input'); m.setType('hidden'); "+
                 "m.setName('_method'); m.setValue('delete'); f.appendChild(m); "+
                 "f.submit(); return false;\">#{LABEL}</a>", @response.body)
  end

  def test_link_to_with_method_for_non_canvas
    get :link_to_with_method
    assert_equal( "<a href=\"#{URL}\" onclick=\"var f = document.createElement('form'); f.style.display = 'none'; "+
                 "this.parentNode.appendChild(f); f.method = 'POST'; f.action = this.href;" +
                 "var m = document.createElement('input'); m.setAttribute('type', 'hidden'); "+
                 "m.setAttribute('name', '_method'); m.setAttribute('value', 'delete'); f.appendChild(m);"+
                 "f.submit();return false;\">#{LABEL}</a>", @response.body)
  end

 def test_link_to_with_confirm_and_method_for_canvas
    get :link_to_with_confirm_and_method, {"fb_sig_in_canvas"=>"1"}
    assert_equal( "<a href=\"#{URL}\" onclick=\"var __obj = this;var __dlg = new Dialog().showChoice(\'#{TITLE}\', \'#{CONTENT}\');"+
                 "__dlg.onconfirm = function() { " + 
                 "var f = document.createElement('form'); f.setStyle('display', 'none'); "+
                 "__obj.getParentNode().appendChild(f); f.setMethod('POST'); f.setAction(__obj.getHref()); " +
                 "var m = document.createElement('input'); m.setType('hidden'); "+
                 "m.setName('_method'); m.setValue('delete'); f.appendChild(m); "+
                 "f.submit(); }; ; return false;\">#{LABEL}</a>", @response.body)
  end
  def test_link_to_with_confirm_and_method_for_non_canvas
    get :link_to_with_confirm_and_method
    assert_equal( "<a href=\"#{URL}\" onclick=\"if (confirm(\'#{CONTENT}\')) { var f = document.createElement('form'); f.style.display = 'none'; "+
                      "this.parentNode.appendChild(f); f.method = 'POST'; f.action = this.href;var m = document.createElement('input'); "+
                      "m.setAttribute('type', 'hidden'); m.setAttribute('name', '_method'); m.setAttribute('value', 'delete'); "+
                      "f.appendChild(m);f.submit(); };return false;\">#{LABEL}</a>", @response.body)
  end

  def test_button_to_without_for_canvas
    get :button_to_without, {"fb_sig_in_canvas"=>"1"}
    assert_equal "<form method=\"post\" action=\"#{URL}\" class=\"button-to\"><div>" +
                 "<input type=\"submit\" value=\"#{LABEL}\" /></div></form>", @response.body
  end
  def test_button_to_without_for_non_canvas
    get :button_to_without
    assert_equal "<form method=\"post\" action=\"#{URL}\" class=\"button-to\"><div>" +
                 "<input type=\"submit\" value=\"#{LABEL}\" /></div></form>", @response.body
  end

  def test_button_to_with_confirm_for_canvas
    get :button_to_with_confirm, {"fb_sig_in_canvas"=>"1"}
    assert_equal "<form method=\"post\" action=\"#{URL}\" class=\"button-to\"><div>" +
                 "<input onclick=\"var __obj = this;var __dlg = new Dialog().showChoice(\'#{TITLE}\', \'#{CONTENT}\');"+
                 "__dlg.onconfirm = function() { "+
                 "__obj.getForm().submit(); };return false;\" type=\"submit\" value=\"#{LABEL}\" /></div></form>", 
                 @response.body
  end
  def test_button_to_with_confirm_for_non_canvas
    get :button_to_with_confirm
    assert_equal "<form method=\"post\" action=\"#{URL}\" class=\"button-to\"><div>"+
                 "<input onclick=\"return confirm(\'#{CONTENT}\');\" type=\"submit\" value=\"#{LABEL}\" /></div></form>",
                 @response.body
  end

  def test_single_quoted_javascript_for_canvas
    get :single_quoted_javascript, {"fb_sig_in_canvas"=>"1"}
    assert_equal( "<a href=\"#{URL}\" onclick=\"var __obj = this;var __dlg = new Dialog().showChoice(\'#{TITLE}\', \'#{CONTENT}\');"+
                 "__dlg.onconfirm = function() { " +
                 "document.setLocation(__obj.getHref()); };return false;\">#{LABEL}</a>", @response.body)
  end

  def test_whitespace_before_quoted_javascript_for_canvas
    get :whitespace_before_quoted_javascript, {"fb_sig_in_canvas"=>"1"}
    assert_equal( "<a href=\"#{URL}\" onclick = \"var __obj = this;var __dlg = new Dialog().showChoice(\'#{TITLE}\', \'#{CONTENT}\');"+
                 "__dlg.onconfirm = function() { " +
                 "document.setLocation(__obj.getHref()); };return false;\">#{LABEL}</a>", @response.body)
  end

  private
  # Ignore whitespace
  def assert_equal(expected, actual)
    actual = actual.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    expected = expected.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    super(expected, actual)
  end

  # stop warnings
  UrlHelperController.append_view_path('nowhere')
  class ActionView::Base
    def template_format 
      "please don't warn"
    end
  end
end
