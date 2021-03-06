require File.dirname(__FILE__) + '/test_helper.rb'
require 'action_controller'
require 'action_controller/test_process'

ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end

module TestUtilities
  # Ignore whitespace
  def assert_equal(expected, actual)
    actual = actual.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    expected = expected.gsub(/\n/, ' ').gsub(/\s+/, ' ')
    super(expected, actual)
  end

  def for_canvas
    {"fb_sig_in_canvas"=>"1"}  
  end
end


class TestController < ActionController::Base
  include Js2Fbjs::Rails::Controller
  after_filter :translate_js_to_fbjs

  private
  def rescue_action(e) raise e end 

  def protect_against_forgery?
     false
  end

  def request_is_for_a_facebook_canvas?
    !params['fb_sig_in_canvas'].blank?
  end
end

class RailsTest < Test::Unit::TestCase
  include TestUtilities
  LABEL = "Test"
  URL = "test.host"
  CONTENT = "r u sure?"
  TITLE = "The page says:"


  class RailsController < TestController
    include Js2Fbjs::Rails::Controller
  
    after_filter :translate_js_to_fbjs
   
    def single_quoted_javascript
      render :text => "<a href=\"#{URL}\" onclick=\'return confirm(\"#{CONTENT}\");\'>#{LABEL}</a>"
    end

    def whitespace_before_quoted_javascript
      render :text => "<a href=\"#{URL}\" onclick = \"return confirm(\'#{CONTENT}\');\">#{LABEL}</a>"
    end

    def script_tagged_javascript
      render :text => "<script>confirm(\'#{CONTENT}\');</script>"
    end
  end

  def setup
    @controller = RailsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_single_quoted_javascript_for_canvas
    get :single_quoted_javascript, for_canvas
    assert_equal( "<a href=\"#{URL}\" onclick=\"var __obj = this; var __dlg = new Dialog().showChoice(\'#{TITLE}\', \'#{CONTENT}\');"+
                 " __dlg.onconfirm = function() { " +
                 "document.setLocation(__obj.getHref()); }; return false;\">#{LABEL}</a>", @response.body)
  end

  def test_whitespace_before_quoted_javascript_for_canvas
    get :whitespace_before_quoted_javascript, for_canvas
    assert_equal( "<a href=\"#{URL}\" onclick = \"var __obj = this; var __dlg = new Dialog().showChoice(\'#{TITLE}\', \'#{CONTENT}\');"+
                 " __dlg.onconfirm = function() { " +
                 "document.setLocation(__obj.getHref()); }; return false;\">#{LABEL}</a>", @response.body)
  end

  def test_script_tagged_javascript_for_canvas
    get :script_tagged_javascript, for_canvas
    assert_equal( "<script>"+
		  "var __dlg = new Dialog().showChoice(\'#{TITLE}\', \'#{CONTENT}\');"+
		  "</script>", @response.body)
  end
end

class RailsUrlHelperTest < Test::Unit::TestCase
  include TestUtilities
  LABEL = "Test"
  URL = "test.host"
  CONTENT = "r u sure?"
  TITLE = "The page says:"

  class UrlHelperController < TestController
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TagHelper
  
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
  end

  def setup
    @controller = UrlHelperController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_link_to_without_for_canvas
    get :link_to_without, for_canvas
    assert_equal("<a href=\"#{URL}\">#{LABEL}</a>", @response.body)
  end
  def test_link_to_without_for_non_canvas
    get :link_to_without
    assert_equal("<a href=\"#{URL}\">#{LABEL}</a>", @response.body)
  end

  def test_link_to_with_confirm_for_canvas
    get :link_to_with_confirm, for_canvas
    assert_equal( "<a href=\"#{URL}\" onclick=\"var __obj = this;var __dlg = new Dialog().showChoice(\'#{TITLE}\', \'#{CONTENT}\');"+
                 "__dlg.onconfirm = function() { " + 
                 "document.setLocation(__obj.getHref()); };return false;\">#{LABEL}</a>", @response.body)
  end

  def test_link_to_with_confirm_for_non_canvas
    get :link_to_with_confirm
    assert_equal( "<a href=\"#{URL}\" onclick=\"return confirm(\'#{CONTENT}\');\">#{LABEL}</a>", @response.body)
  end

  def test_link_to_with_method_for_canvas
    get :link_to_with_method, for_canvas
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
    get :link_to_with_confirm_and_method, for_canvas
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
    get :button_to_without, for_canvas
    assert_equal "<form method=\"post\" action=\"#{URL}\" class=\"button-to\"><div>" +
                 "<input type=\"submit\" value=\"#{LABEL}\" /></div></form>", @response.body
  end
  def test_button_to_without_for_non_canvas
    get :button_to_without
    assert_equal "<form method=\"post\" action=\"#{URL}\" class=\"button-to\"><div>" +
                 "<input type=\"submit\" value=\"#{LABEL}\" /></div></form>", @response.body
  end

  def test_button_to_with_confirm_for_canvas
    get :button_to_with_confirm, for_canvas
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
end

class PrototypeHelperTest < Test::Unit::TestCase
  include TestUtilities
  LABEL = "Test"
  URL = "test.host"
  CONTENT = "r u sure?"
  TITLE = "The page says:"

  class PrototypeHelperController < TestController
    include ActionView::Helpers::PrototypeHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TagHelper

    def remote_function_without
      render :text=>"<script>#{self.remote_function(:url=>URL)}</script>"
    end

    def remote_function_with_confirm
      render :text=>"<script>#{self.remote_function({:url=>URL, :confirm=>CONTENT})}</script>"
    end

    def submit_to_remote_without
      render :text=>self.submit_to_remote(LABEL, LABEL, :url=>URL)
    end
  end

  def setup
    @controller = PrototypeHelperController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_remote_function_without_for_canvas
    get :remote_function_without, for_canvas
    assert_equal "<script>new Ajax.Request('#{URL}', { asynchronous: true, evalScripts: true });</script>",
	@response.body
  end

  def test_remote_function_without_for_non_canvas
    get :remote_function_without
    assert_equal "<script>new Ajax.Request('#{URL}', {asynchronous:true, evalScripts:true})</script>",
	@response.body
  end

  def test_remote_function_with_confirm_for_canvas
    get :remote_function_with_confirm, for_canvas
    assert_equal "<script>var __obj = this;var __dlg = new Dialog().showChoice(\'#{TITLE}\', \'#{CONTENT}\');"+
	"__dlg.onconfirm = function() { new Ajax.Request('#{URL}', { asynchronous: true, evalScripts: true }); "+
	"};</script>",
	@response.body
  end

  def test_remote_function_with_confirm_for_non_canvas
    get :remote_function_with_confirm
    assert_equal "<script>if (confirm('#{CONTENT}')) { new Ajax.Request('#{URL}', {asynchronous:true, "+
	"evalScripts:true}); }</script>",
	@response.body
  end  

  def test_submit_to_remote_without_for_canvas
    get :submit_to_remote_without, for_canvas
    assert_equal "<input name=\"#{LABEL}\" onclick=\"new Ajax.Request('#{URL}', { asynchronous: true, "+
		"evalScripts: true, parameters: Form.serialize(this.getForm()) }); return false;\" "+
		"type=\"button\" value=\"#{LABEL}\" />", @response.body
  end

  def test_submit_to_remote_without_for_non_canvas
    get :submit_to_remote_without
    assert_equal "<input name=\"#{LABEL}\" onclick=\"new Ajax.Request('#{URL}', {asynchronous:true, "+
		 "evalScripts:true, parameters:Form.serialize(this.form)}); return false;\" "+
		 "type=\"button\" value=\"#{LABEL}\" />", @response.body
  end  
end
