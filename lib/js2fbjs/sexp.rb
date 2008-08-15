# Courtesy of the ParseTree Gem.

$TESTING ||= false # unless defined $TESTING

module Js2Fbjs

##
# Sexps are the basic storage mechanism of SexpProcessor.  Sexps have
# a +type+ (to be renamed +node_type+) which is the first element of
# the Sexp. The type is used by SexpProcessor to determine whom to
# dispatch the Sexp to for processing.

class Sexp < Array

  @@array_types = [ :array, :args, ]

  ##
  # Create a new Sexp containing +args+.
  def initialize(*args)
    super(args)
  end

  def flatten(*args)
    p "hello"
    self
  end
  ##
  # Creates a new Sexp from Array +a+
  def self.from_array(a)
    ary = Array === a ? a : [a]

    result = self.new

    ary.each do |x|
      case x
      when Sexp
        result << x
      when Array
        result << self.from_array(x)
      else
        result << x
      end
    end

    result
  end

  def ==(obj) # :nodoc:
    if obj.class == self.class then
      super
    else
      false
    end
  end

  ##
  # Returns true if this Sexp's pattern matches +sexp+.
  # 
  # == Examples
  # s(:var, 'hello') === s(:var, 'hello')
  #  -> true
  # s(:str, 'hello') === s(:var, 'hello')
  #  -> false
  def ===(sexp)
    return nil unless Sexp === sexp
    pattern = self # this is just for my brain

    return true if pattern == sexp

#    sexp.each do |subset|
#      return true if pattern === subset
 #   end

    return nil
  end

  ##
  # Returns true if this Sexp matches +pattern+.  (Opposite of #===.)
  def =~(pattern)
    return pattern === self
  end

  ##
  # Returns true if the node_type is +array+ or +args+.
  #
  # REFACTOR: to TypedSexp - we only care when we have units.
  def array_type?
    type = self.first
    @@array_types.include? type
  end

  def compact # :nodoc:
    self.delete_if { |o| o.nil? }
  end

  ##
  # Enumeratates the sexp yielding to +b+ when the node_type == +t+.
  def each_of_type(t, &b)
    each do | elem |
      if Sexp === elem then
        elem.each_of_type(t, &b)
        b.call(elem) if elem.first == t
      end
    end
  end

  ##
  # Replaces all elements whose node_type is +from+ with +to+. Used
  # only for the most trivial of rewrites.
  def find_and_replace_all(from, to)
    each_with_index do | elem, index |
      if Sexp === elem then
        elem.find_and_replace_all(from, to)
      else
        self[index] = to if elem == from
      end
    end
  end

  ##
  # Replaces all Sexps matching +pattern+ with Sexp +repl+.
  def gsub(pattern, repl)
    return repl.clone if pattern == self # I don't why we have to clone but we do or I get nil?

    new = self.map do |subset|
      case subset
      when Sexp then
        subset.gsub(pattern, repl)
      else
        subset
      end
    end

    return Sexp.from_array(new)
  end

  def inspect # :nodoc:
    sexp_str = self.map {|x|x.inspect}.join(', ')
    return "s(#{sexp_str})"
  end

  ##
  # Returns the node named +node+, deleting it if +delete+ is true.
  def method_missing(meth, delete=false)
    matches = find_all { | sexp | Sexp === sexp and sexp.first == meth }

    case matches.size
    when 0 then
      nil
    when 1 then
      match = matches.first
      delete match if delete
      match
    else
      raise NoMethodError, "multiple nodes for #{meth} were found in #{inspect}"
    end
  end

  def pretty_print(q) # :nodoc:
    q.group(1, 's(', ')') do
      q.seplist(self) {|v| q.pp v }
    end
  end

  ##
  # Returns the Sexp without the node_type.
  def sexp_body
    self[1..-1]
  end

  ##
  # If run with debug, Sexp will raise if you shift on an empty
  # Sexp. Helps with debugging.
  def shift
    raise "I'm empty" if self.empty?
    super
  end if $DEBUG or $TESTING

  ##
  # Returns the bare bones structure of the sexp.
  # s(:a, :b, s(:c, :d), :e) => s(:a, s(:c))
  def structure
    result = self.class.new
    if Array === self.first then
      result = self.first.structure
    else
      result << self.first
      self.grep(Array).each do |subexp|
        result << subexp.structure
      end
    end
    result
  end

  ##
  # Replaces the Sexp matching +pattern+ with +repl+.
  def sub(pattern, repl)
    return repl.dup if pattern == self

    done = false

    new = self.map do |subset|
      if done then
        subset
      else
        case subset
        when Sexp then
          if pattern == subset then
            done = true
            repl.dup
          elsif pattern === subset then
            done = true
            subset.sub pattern, repl
          else
            subset
          end
        else
          subset
        end
      end
    end

    return Sexp.from_array(new)
  end

  def to_a # :nodoc:
    self.map { |o| Sexp === o ? o.to_a : o }
  end

  def to_s # :nodoc:
    inspect
  end

end

class Any
  def ==(o)
    true
  end

  def inspect
    "ANY"
  end
end
class OneOf
  def initialize(p)
    @posibles = p
  end
 
  def ==(o)
    @posibles.include?(o)
  end

  def inspect
    "ONE OF #{@posibles}"
  end
end

module SexpMatchSpecials
  def ANY(); return Any.new; end
  def ONE_OF(p); return OneOf.new(p); end
end

module SexpUtility
  ##
  # This is just a stupid shortcut to make indentation much cleaner.
  def s(*args)
    Sexp.new(*args)
  end
end

end
