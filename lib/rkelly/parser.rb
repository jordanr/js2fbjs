require 'rkelly/tokenizer'
require 'rkelly/generated_parser'

module RKelly
  class Parser < RKelly::GeneratedParser
    TOKENIZER = Tokenizer.new
    attr_accessor :logger
    def initialize
      @tokens = []
      @logger = nil
      @terminator = false
    end

    # Parse +javascript+ and return an AST
    def parse(javascript)
      @tokens = TOKENIZER.tokenize(javascript)
      @position = 0
      SourceElementsNode.new([do_parse].flatten)
    end

    private
    def on_error(error_token_id, error_value, value_stack)
      error_token = token_to_str(error_token_id)
      if logger
        logger.error(token_to_str(error_token_id))
        logger.error("error value: #{error_value}")
        logger.error("error stack: #{value_stack}")
      end
      raise ParseError, "value: #{error_value}, stack: #{value_stack}" unless allow_auto_semi?(error_token)
    end

    def next_token
      begin
        return [false, false] if @position >= @tokens.length
        n_token = @tokens[@position]
        @position += 1
        case @tokens[@position - 1][0]
        when :COMMENT
          @terminator = true if n_token[1] =~ /^\/\//
        when :S
          @terminator = true if n_token[1] =~ /^[\r\n]/
        end
      end while([:COMMENT, :S].include?(n_token[0]))
      n_token
    end
  end
end
