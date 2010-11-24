class Lexr
	def self.that(&block)
		dsl = Lexr::Dsl.new
		block.arity == 1 ? block[dsl] : dsl.instance_eval(&block)
		dsl
	end
	
	def initialize(text, rules)
		@text, @rules = text, rules
		@current = nil
		@position = 0
	end

	def next
		return @current = Lexr::Token.end if @position >= @text.length
		@rules.each do |rule|
			if result = rule.pattern.instance_of?(Regexp) ? regexp_match(rule.pattern) : literal_match(rule.pattern)
				result = rule.converter[result] if rule.converter
				return self.send :next if rule.ignore?
				return @current = Lexr::Token.new(result, rule.symbol)
			end
		end
		raise Lexr::UnmatchableTextError.new(unprocessed_text[0..0], @position)
	end
	
	def peek
	  pos = @position
	  cur = @current
		result = self.send :next
		@position = pos
		@current = cur
		result
	end
	
	def current
		@current
	end
	
	def end?
		@current == Lexr::Token.end
	end
	
	private
	
	def unprocessed_text
		@text[@position..-1]
	end
	
	def regexp_match(regex)
		return nil unless m = unprocessed_text.match(/^#{regex}/)
		@position += m.end(0)
		m[0]
	end
	
	def literal_match(lit)
		return nil unless unprocessed_text[0..lit.length-1] == lit
		@position += lit.length
		lit
	end
	
	class Token
		attr_reader :value, :type
	
		def initialize(value, type = nil)
			@value, @type = value, type
		end
		
		def self.method_missing(sym, *args)
			self.new(args.first, sym)
		end
		
		def to_s
			"#{type}(#{value})"
		end
		
		def ==(other)
			@type == other.type && @value == other.value
		end
	end
	
	class Rule
		attr_reader :pattern, :symbol
		
		def converter ; @opts[:convert_with] ; end
		def ignore? ; @opts[:ignore] ; end
		
		def initialize(pattern, symbol, opts = {})
			@pattern, @symbol, @opts = pattern, symbol, opts
		end
		
		def ==(other)
			@pattern == other.pattern && 
				@symbol == other.symbol && 
				@opts[:convert_with] == other.converter && 
				@opts[:ignore] == other.ignore?
		end
	end
	
	class Dsl
		def initialize
			@rules = []
		end
		
		def matches(rule_hash)
			pattern = rule_hash.keys.reject { |k| k.class == Symbol }.first
			symbol = rule_hash[pattern]
			opts = rule_hash.delete_if { |k, v| k.class != Symbol }
			@rules << Rule.new(pattern, symbol, opts)
		end
		
		def ignores(rule_hash)
			matches rule_hash.merge(:ignore => true)
		end
		
		def new(str)
			Lexr.new(str, @rules)
		end
	end
	
	class UnmatchableTextError < StandardError
		attr_reader :character, :position
		
		def initialize(character, position)
			@character, @position = character, position
		end
		
		def message
			"Unexpected character '#{character}' at position #{position + 1}"
		end
		
		def inspect
			message
		end
	end
end