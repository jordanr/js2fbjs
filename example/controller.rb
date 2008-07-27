class SampleController < ApplicationController
  after_filter :translate_js_to_fbjs

  def index
    render :text=>"<script>confirm('hello');</script>"
  end
end

