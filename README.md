# Lexr

Lexr is a lightweight lexical analyser written in ruby, it has no dependencies, has good test coverage, looks pretty and reads well.

Install with

	gem install lexr

## An example: Expressions

	require 'rubygems'
	require 'lexr'

	ExpressionLexer = Lexr.that {
		ignores /\s+/ => :whitespace
		
		legal_place_for_binary_operator = lambda { |prev| [:addition, 
																:subtraction, 
																:multiplication, 
																:division,
																:left_parenthesis,
																:start].include? prev.type }
		
		matches "+" => :addition, :unless => legal_place_for_binary_operator
		matches "-" => :subtraction, :unless => legal_place_for_binary_operator
		matches "*" => :multiplication, :unless => legal_place_for_binary_operator
		matches "/" => :division, :unless => legal_place_for_binary_operator
		
		matches "(" => :left_parenthesis
		matches ")" => :right_parenthesis
		
		matches /[-+]?[0-9]*\.?[0-9]+/ => :number, :convert_with => lambda { |v| Float(v) }
	}

	lexer = ExpressionLexer.new("-1 * 12.5 / (55 + 2 - -56)")

	until lexer.end?
		puts lexer.next
	end

results in an output of

	number(-1.0)
	multiplication(*)
	number(12.5)
	division(/)
	left_parenthesis(()
	number(55.0)
	addition(+)
	number(2.0)
	subtraction(-)
	number(-56.0)
	right_parenthesis())
	end()
	
if you added a % in there somewhere, you'd get a Lexr::UnmatchableTextError with a message like this:

	=> Unexpected character '%' at position 5
	
and that is pretty much every feature so far. Please let me know of any bugs or additions that you'd like to see!