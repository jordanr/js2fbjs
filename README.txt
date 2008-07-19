== Js2Fbjs
  http://github.com/jordanr/js2fbjs/tree/master

== Description
This library will parse JavaScript and translate it 
into Facebook JavaScript.

== Features
* Integrates with Facebooker
* Translates JavaScript DOM accessor into getter/setter functions
* Translates Rails JavaScript helpers

== Requirements
None to use, although Racc 1.4.5 (Ruby yacc) generates the JavaScript 
parser.  You'll need Racc to rebuild the parser.  Easy to install from:
  http://i.loveruby.net/en/projects/racc/

== Install
As a Rails plugin by:
  script/plugin install git://github.com/jordanr/js2fbjs.git

== Example
  require 'js2fbjs'

  puts FbjsRewriter.translate(
    "if(confirm('Are you sure')) document.location = this.href;"
  )
  -->  "__obj = this;
	__dlg = new Dialog().showChoice('The page says:', 'Are you sure?');
     	__dlg.onconfirm = function() { document.setLocation(__obj.getHref()) }

== Author
  Copyright 2008 by Richard Jordan

== Acknowledgments
* Developers of the ParseTree Gem wrote the S-expression files.  Thanks!

* Aaron Patterson beautifully wrote RKelly.  Thanks Aaron!
  Copyright (c) 2007 by Aaron Patterson (aaronp@rubyforge.org) 
  http://rkelly.rubyforge.org/

* Paul Sowden wrote the original JavaScript parser, rbNarcissus.
  Thanks Paul!
  http://idontsmoke.co.uk/2005/rbnarcissus/
  
== License
This library is distributed under the GPL.  Please see the LICENSE[link://files/LICENSE_txt.html] file.
