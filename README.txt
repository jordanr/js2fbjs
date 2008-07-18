= Js2Fbjs
  http://github.com/jordanr/js2fbjs/tree/master

== DESCRIPTION
This library will parse JavaScript and translate it 
into Facebook JavaScript.

== Example
  require 'js2fbjs'

  puts FbjsRewriter.translate(
    "for(var i = 0; i < 10; i++) { var x = 5 + 5; }"
  )

== Author
  Copyright 2008 by Richard Jordan

== Acknowledgments
* Aaron Patterson beautifully wrote RKelly.  Thanks Aaron!
  Copyright (c) 2007 by Aaron Patterson (aaronp@rubyforge.org) 
  http://rkelly.rubyforge.org/

* Paul Sowden wrote the original JavaScript parser, rbNarcissus.
  Thanks Paul!
  http://idontsmoke.co.uk/2005/rbnarcissus/
  
== License
This library is distributed under the GPL.  Please see the LICENSE[link://files/LICENSE_txt.html] file.
