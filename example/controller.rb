class SampleController < ApplicationController
  translate_js_to_fbjs

  def index
    render :text=>"testing ... <script>confirm('hello');</script>"
  end
end

