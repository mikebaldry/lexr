## Lexr

Lexr is a lightweight lexical analyser written in ruby, it has no dependencies, has good test coverage, looks pretty and reads well.

# An example: Expressions

	ExpressionLexer = Lexr.that {
		ignores /\s+/ => :whitespace
		matches /[-+]?[0-9]*\.?[0-9]+/ => :number, :convert_with => lambda { |v| Float(v) }
		matches "+" => :addition
		matches "-" => :subtraction
		matches "*" => :multiplication
		matches "/" => :division
		matches "(" => :left_parenthesis
		matches ")" => :right_parenthesis
	}

	lexer = ExpressionLexer.new("1 * 12.5 / (55 + 2 - 56)")

	while (token = lexer.next) != Lexr::Token.end
		puts token
	end

results in an output of

	number(1.0)
	multiplication(*)
	number(12.5)
	division(/)
	left_parenthesis(()
	number(55.0)
	addition(+)
	number(2.0)
	subtraction(-)
	number(56.0)
	right_parenthesis())
	
and that pretty is every feature so far. Please let me know of any bugs or additions that you'd like to see!