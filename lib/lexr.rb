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
		  next unless result = rule.match(unprocessed_text)
		  @position += result.characters_matched
		  return self.next if rule.ignore?
		  return @current = result.token
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
	  
	  def match(text)
	    text_matched = self.send :"#{pattern.class.name.downcase}_matcher", text
	    return nil unless text_matched
	    value = converter ? converter[text_matched] : text_matched
	    Lexr::MatchData.new(text_matched.length, Lexr::Token.new(value, symbol))
    end
		
		def ==(other)
			@pattern == other.pattern && 
				@symbol == other.symbol && 
				@opts[:convert_with] == other.converter && 
				@opts[:ignore] == other.ignore?
		end
		
		private
		
		def string_matcher(text)
		  return nil unless text[0..pattern.length-1] == pattern
      pattern
	  end
	  
	  def regexp_matcher(text)
	    return nil unless m = text.match(/\A#{pattern}/)
		  m[0]
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
	
	class MatchData
	  attr_reader :characters_matched, :token
	  
	  def initialize(characters_matched, token)
	    @characters_matched = characters_matched
	    @token = token
    end
  end
end