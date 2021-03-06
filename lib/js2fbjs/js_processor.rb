require 'js2fbjs/sexp_processor'
require 'js2fbjs'

# Turns S-expressions into JavaScript.
module Js2Fbjs

class JsProcessor < SexpProcessor

  def self.translate(str, strict = false)
    jstree = Js2Fbjs::Parser.new(strict).parse(str)
    js = self.new.process(jstree)
    raise SexpProcessorError, "translation is the empty string" if js.empty? and !str.empty?
    js
  end

  def initialize
    super
    @indent = 0
    self.auto_shift_type = true
    self.strict = true
    self.expected = String
  end

  def process exp
    exp = Sexp.from_array(exp) if Array === exp unless Sexp === exp
    super exp
  end

  ############################################################
  # Processors  
      # array nodes
      def process_SourceElements(exp)
        res = exp.map { |x| "#{indent}#{process(x)}" }.join("\n")
	exp.clear
	res.to_s
      end
      def process_Arguments(exp)
        res = exp.map { |x| process(x) }.join(', ')
	exp.clear
	res.to_s
      end

      def process_Parameters(exp)
	res = exp.join(', ')
	exp.clear
	res.to_s
      end

      def process_Array(exp)
        res = "[#{exp.map { |x| x ? process(x) : '' }.join(', ')}]"
	exp.clear
	res.to_s
      end
      def process_VarStatement(exp)
        res = "var #{exp.map { |x| process(x) }.join(', ')};"
	exp.clear
	res.to_s
      end
      def process_ConstStatement(exp)
        res = "const #{exp.map { |x| process(x) }.join(', ')};"
	exp.clear
	res.to_s
      end
      def process_ObjectLiteral(exp)
        @indent += 1
        lit = "{" + (exp.length > 0 ? "\n" : ' ') +
          exp.map { |x| "#{indent}#{process(x)}" }.join(",\n") +
          (exp.length > 0 ? "\n" : '') + '}'
        @indent -= 1
	exp.clear # get rid of it now
        lit.to_s
      end

      def process_CaseBlock(exp)
        @indent += 1
        res = "{\n" + (exp ? exp.map { |x| process(x) }.join('') : '') +
          "#{@indent -=1; indent}}"
	exp.clear
	res.to_s
      end
    ####### end of array nodes

    ##### specials
      def process_FunctionDecl(exp)
        "#{indent}function #{exp.shift}(" +
          "#{process(exp.shift)})" +
          "#{process(exp.shift)}"
      end

      def process_FunctionBody(exp)
        @indent += 1
        "{\n#{process(exp.shift)}\n#{@indent -=1; indent}}"
      end

      def process_For(exp)	
        init, test, counter = exp.shift, exp.shift, exp.shift
	init = init ? process(init) : ';'
        test    = test ? process(test) : ''
        counter = counter ? process(counter) : ''
        "for(#{init} #{test}; #{counter}) #{process(exp.shift)}"
      end
      def process_Block(exp)
        @indent += 1
        "{\n#{process(exp.shift)}\n#{@indent -=1; indent}}"
      end

      def process_FunctionExpr(exp)
	name = exp.shift
        "#{name}(#{process(exp.shift)}) " +
          "#{process(exp.shift)}"
      end

      def process_If(exp)
        res = "if(#{process(exp.shift)}) #{process(exp.shift)}"
	elsy = exp.shift
	res + (elsy ? " else #{process(elsy)}" : '')
      end

      def process_Conditional(exp)
        "#{process(exp.shift)} ? #{process(exp.shift)} : " +
          "#{process(exp.shift)}"
      end

      def process_ForIn(exp)
        "for(#{process(exp.shift)} in #{process(exp.shift)}) " +
          "#{process(exp.shift)}"
      end

      def process_Try(exp)
        res = "try #{process(exp.shift)}"
	catch = exp.shift
	catch_block = exp.shift
	res += (catch ? " catch(#{catch}) #{process(catch_block)}" : '') 
	finally = exp.shift
	res + (finally ? " finally #{process(finally)}" : '')
      end

      def process_CaseClause(exp)
	case_clause = exp.shift
        case_code = "#{indent}case #{case_clause ? process(case_clause) : nil}:\n"
        @indent += 1
        case_code += "#{process(exp.shift)}\n"
        @indent -= 1
        case_code
      end
     ########

      EXP = %w{
        Number Regexp Resolve String
      }
      EXP.each do |type|
        define_method("process_#{type}") do |exp|
          exp.shift.to_s
        end
      end
      FIXED_EXP = 
      [
        [:EmptyStatement, ';'],
	[:False, 'false'],
	[:Null, 'null'],
	[:This, 'this'],
	[:True, 'true']
      ]
      FIXED_EXP.each do |type, value|
        define_method("process_#{type}") do |exp|
	  exp.shift # throw away
          value
        end
      end

      [
	[:Break, 'break'],
	[:Continue, 'continue'],
      ].each do |type, keyword|
        define_method("process_#{type}") do |exp|
	  value = exp.shift
          "#{keyword}" + (value ? " #{value}" : '') + ';'       
        end
      end
      def process_Return(exp)
	  value = exp.shift
          "return" + (value ? " #{process(value)}" : '') + ';'       
      end

      PROC =
      [
	[:AssignExpr, ' = '],
	[:BitwiseNot, '~'],
	[:Delete, 'delete '],
	[:Element, ''],
	[:ExpressionStatement, '', ';'],
	[:LogicalNot, '!'],
	[:UnaryMinus, '-'],
	[:UnaryPlus, '+'],
	[:Throw, 'throw ', ';'],
	[:TypeOf, 'typeof '],
	[:Void, 'void(', ')']
      ]
      PROC.each do |name, op1, op2|
        define_method("process_#{name}") do |exp|
          "#{op1}#{process(exp.shift)}#{op2}"
        end
      end

      PROC_PROC = 
      [
        [:Add, ' + '],
        [:BitAnd, ' & '],
        [:BitOr, ' | '],
        [:BitXOr, ' ^ '],
	[:BracketAccessor, '[', '',']'],
	[:Comma, ', '],
        [:Divide, ' / '],
	[:DoWhile, ' while(', 'do ', ');'],
        [:Equal, ' == '],
	[:FunctionCall, '(', '', ')'],
        [:Greater, ' > '],
        [:GreaterOrEqual, ' >= '],
        [:In, ' in '],
        [:InstanceOf, ' instanceof '],
        [:LeftShift, ' << '],
        [:Less, ' < '],
        [:LessOrEqual, ' <= '],
        [:LogicalAnd, ' && '],
        [:LogicalOr, ' || '],
        [:Modulus, ' % '],
        [:Multiply, ' * '],
	[:NewExpr, '(', 'new ', ')'],
        [:NotEqual, ' != '],
        [:NotStrictEqual, ' !== '],
        [:OpAndEqual, ' &= '],
        [:OpDivideEqual, ' /= '],
        [:OpLShiftEqual, ' <<= '],
	[:OpEqual, ' = '],
        [:OpMinusEqual, ' -= '],
        [:OpModEqual, ' %= '],
        [:OpMultiplyEqual, ' *= '],
        [:OpOrEqual, ' |= '],
        [:OpPlusEqual, ' += '],
        [:OpRShiftEqual, ' >>= '],
        [:OpURShiftEqual, ' >>>= '],
        [:OpXOrEqual, ' ^= '],
        [:RightShift, ' >> '],
        [:StrictEqual, ' === '],
        [:Subtract, ' - '],
        [:UnsignedRightShift, ' >>> '],
	[:While, ') ', 'while('],
	[:Switch, ') ', 'switch('],
	[:With, ') ', 'with(']
      ]
      PROC_PROC.each do |name, op_mid, op_pre, op_post|
        define_method("process_#{name}") do |exp|
          "#{op_pre}#{process(exp.shift)}#{op_mid}#{process(exp.shift)}#{op_post}"
        end
      end

      EXP_PROC = 
      [
	[:Prefix],
	[:Label, ': '],
	[:Property, ': '],
	[:GetterProperty, '','get '],
	[:SetterProperty, '','set ']
      ]
      EXP_PROC.each do |name, op_mid, op_pre, op_post|
        define_method("process_#{name}") do |exp|
          "#{op_pre}#{exp.shift}#{op_mid}#{process(exp.shift)}#{op_post}"
        end
      end
	# exp.first ? exp.shift : nil
      def process_VarDecl(exp)
        "#{exp.shift}#{process(exp.shift)}"
      end

      # op? proc op? exp op?
      def process_Postfix(exp)
        "#{process(exp.shift)}#{exp.shift}"
      end
      def process_DotAccessor(exp)
        "#{process(exp.shift)}.#{exp.shift}"
      end

  ############################################################
  # Utility Methods: 
  private
  def indent; ' ' * @indent * 2; end

end

end
