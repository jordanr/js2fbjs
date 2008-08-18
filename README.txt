== Js2Fbjs
  Repo: http://github.com/jordanr/js2fbjs/tree/master
  Rdoc: http://db240296.fb.joyent.us:3070/rdoc/

== Description
This library will parse JavaScript and translate it 
into Facebook JavaScript.

Check out the FBJS test console at http://apps.new.facebook.com/jstofbjs/
(you may have to copy and paste the url).

== Features
* Integrates with Facebooker
* Translates:
  ** JavaScript DOM accessor into getter/setter functions 
  ** Built-in functions, i.e. confirm('...') and alert('...')
  ** Rails JavaScript helpers
  ** Rails Prototype helpers with facebooker.js
* Throws errors for impossible code (like extending built-in objects, i.e. Array.prototype)
* Well tested

== Requirements 
None to use, although Racc 1.4.5 (Ruby yacc) generates the JavaScript parser.  
You'll need Racc to rebuild the parser.  Easy to install from:
  http://i.loveruby.net/en/projects/racc/

== Install
As a Rails plugin by:
  script/plugin install git://github.com/jordanr/js2fbjs.git

You must also have Facebooker:
  script/plugin install git://github.com/mmangino/facebooker.git

Then, put either "translate_js_to_fbjs" or "strictly_translate_js_to_fbjs"
at the top of your controller.  Either function will add an after filter
to your controller.  You can use the same options as any after_filter.

"strictly_translate_js_to_fbjs" gives better error messages but also fails
to translate more often.  For instance, "translate_js_to_fbjs" will accept,
  do_it()
but "strictly_translate_js_to_fbjs" will throw an error for a missing 
semi-colon.  You must put,
  do_it();
then it'll also accept.

== Example
  class SampleController < ApplicationController
    translate_js_to_fbjs
    
    def index
      render :text=>"testing ... <script>confirm('Are you sure')</script>"
    end
  end

== Acknowledgments
* Developers of the ParseTree Gem wrote the S-expression files.  Thanks!

* Aaron Patterson beautifully wrote RKelly.  Thanks Aaron!
  Copyright (c) 2007 by Aaron Patterson (aaronp@rubyforge.org) 
  http://rkelly.rubyforge.org/

* Paul Sowden wrote the original JavaScript parser, rbNarcissus.
  Thanks Paul!
  http://idontsmoke.co.uk/2005/rbnarcissus/
  
== License
This library is distributed under the GPL.  Please see the LICENSE file.
