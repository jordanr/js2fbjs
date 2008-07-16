#!/usr/bin/env ruby -w

begin require 'rubygems'; rescue LoadError; end
require 'js2js'

class Js2Fbjs < Js2Js

  def process exp
    exp = Sexp.from_array(exp) if Array === exp unless Sexp === exp
#    p exp
    super exp
  end

  ############################################################
  # Processors  
#	[:FunctionCall, '(', '', ')'],
#	[:OpEqual, '='],
 #     def process_DotAccessor(exp)
  #      "#{process(exp.shift)}.#{exp.shift}"
   #   end

  ############################################################
  # Rewriters:

  ############################################################
  # Utility Methods: 
  private
  def indent; ' ' * @indent * 2; end

end

