require 'js2fbjs/tokenizer'
require 'js2fbjs/generated_parser'

module Js2Fbjs
  class Parser < Js2Fbjs::GeneratedParser
    TOKENIZER = Tokenizer.new
    attr_accessor :logger
    def initialize
      @tokens = []
      @logger = nil
      @terminator = false
    end

    # Parse +javascript+ and return S-expressions
    def parse(javascript)
      @tokens = TOKENIZER.tokenize(javascript)
      @position = 0
      combine(:SourceElements, flatten_unless_sexp([do_parse]) )
    end

    private
    def on_error(error_token_id, error_value, value_stack)
      if false# true
        $stderr.puts(token_to_str(error_token_id))
        $stderr.puts("error value: #{error_value}")
        $stderr.puts("error stack: #{value_stack}")
      end
      raise ParseError, "on #{error_value} with stack #{value_stack.to_s}"
    end

    def next_token
      @terminator = false
      begin
        return [false, false] if @position >= @tokens.length
        n_token = @tokens[@position]
        @position += 1
        case @tokens[@position - 1][0]
        when :COMMENT
          @terminator = true if n_token[1] =~ /^\/\//
        when :S
          @terminator = true if n_token[1] =~ /[\r\n]/
        end
      end while([:COMMENT, :S].include?(n_token[0]))

      @prev_token = n_token
    end
  end
end
