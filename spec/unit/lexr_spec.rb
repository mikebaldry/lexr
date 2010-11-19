require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe "Creating an instance" do
	it "should store the parameters and initialize the position" do
		subject = Lexr.new("test", [123])
		subject.instance_eval do
			@text.should == "test"
			@position.should == 0
			@current.should == nil
			@rules.should == [123]
		end
  end

	it "should not be at the end" do
		subject = Lexr.new("test", [123])
		subject.end?.should be_false
	end
end

describe "Peeking the next token" do
	it "should return the next token but not advance the string" do
		subject = Lexr.new("abcd", [Lexr::Rule.new(/[a-z]/, :a_letter)])
		subject.peek.value.should == "a"
		subject.peek.value.should == "a"
		subject.next.value.should == "a"
		subject.next.value.should == "b"
	end
	
	it "should not change the current token" do
		subject = Lexr.new("abcd", [Lexr::Rule.new(/[a-z]/, :a_letter)])
		subject.current.should == nil
		subject.peek.value.should == "a"
		subject.current.should == nil
	end
end

describe "Getting the next token" do
	it "should return :end token when all tokens are read" do
		subject = Lexr.new("abc", [])
		subject.instance_eval { @position = 3 }
		subject.next.should == Lexr::Token.end
		subject.current.should == Lexr::Token.end
		subject.end?.should be_true
	end
	
	it "should advance the string and return the correct token for a matching literal" do
		subject = Lexr.new("ab", [Lexr::Rule.new("a", :an_a)])
		subject.next.should == Lexr::Token.an_a("a")
		subject.current.should == Lexr::Token.an_a("a")
		subject.end?.should be_false
		subject.send(:unprocessed_text).should == "b"
	end
	
	it "should advance the string and return the correct token for a matching regex" do
		subject = Lexr.new("ab", [Lexr::Rule.new(/[a-z]/, :a_letter)])
		subject.next.should == Lexr::Token.a_letter("a")
		subject.send(:unprocessed_text).should == "b"
	end
	
	it "should use the conversion block to convert a string result into another type" do
		subject = Lexr.new("ab", [Lexr::Rule.new(/[a-z]/, :a_letter, :convert_with => lambda {123})])
		subject.next.should == Lexr::Token.a_letter(123)
		subject.current.should == Lexr::Token.a_letter(123)
		subject.end?.should be_false
	end
	
	it "should match and advance but not return the token (should return the next token after it) when using ignore" do
		subject = Lexr.new("a1", [Lexr::Rule.new(/[a-z]/, :a_letter, :ignore => true), 
														  Lexr::Rule.new(/[0-9]/, :a_number)])
		subject.next.should == Lexr::Token.a_number("1")
	end
	
	it "should raise an error if it is unable to match a rule" do
		subject = Lexr.new(":1", [Lexr::Rule.new("1", :an_a)])
		lambda { subject.next }.should raise_error(Lexr::UnmatchableTextError, "Unexpected character ':' at position 1")
	end
end

describe "A pretty dsl" do
	it "should store a basic rule entered with the correct values and no options" do
		subject = Lexr.that {
			matches "abc" => :mj
		}
		rules = subject.instance_eval { @rules }
		rules.first.should == Lexr::Rule.new("abc", :mj)
	end
	
	it "should store a rule with options correctly" do
		subject = Lexr.that {
			matches /[0-9]+/ => :number, :convert => :test
		}
		rules = subject.instance_eval { @rules }
		rules.first.should == Lexr::Rule.new(/[0-9]+/, :number, :convert => :test)
	end
	
	it "should store an ignore rule correctly" do
		subject = Lexr.that {
			ignores /\s+/ => :whitespace
		}
		rules = subject.instance_eval { @rules }
		rules.first.should == Lexr::Rule.new(/\s+/, :whitespace, :ignore => true)
	end
	
	it "should create instances of a Lexr containing the correct rules and text" do
		subject = Lexr.that {
			matches /[0-9]+/ => :number, :convert => :test
			ignores /\s+/ => :whitespace
		}.new(" 123  ")
		
		subject.instance_eval { @text }.should == " 123  "
		subject.instance_eval { @rules }.should == [
																				Lexr::Rule.new(/[0-9]+/, :number, :convert => :test),
																				Lexr::Rule.new(/\s+/, :whitespace, :ignore => true)]
	end
end

describe "Putting it all together" do
	it "should be able to process a mathmatical expression" do
		subject = Lexr.that {
			ignores /\s+/ => :whitespace
			matches /[-+]?[0-9]*\.?[0-9]+/ => :number, :convert_with => lambda { |v| Float(v) }
			matches "+" => :addition
			matches "-" => :subtraction
			matches "*" => :multiplication
			matches "/" => :division
			matches "(" => :left_parenthesis
			matches ")" => :right_parenthesis
		}
		lexer = subject.new("1 * 12.5 / (55 + 2 - 56)")
		lexer.next.should == Lexr::Token.number(1)
		lexer.next.should == Lexr::Token.multiplication("*")
		lexer.next.should == Lexr::Token.number(12.5)
		lexer.next.should == Lexr::Token.division("/")
		lexer.next.should == Lexr::Token.left_parenthesis("(")
		lexer.next.should == Lexr::Token.number(55)
		lexer.next.should == Lexr::Token.addition("+")
		lexer.next.should == Lexr::Token.number(2)
		lexer.next.should == Lexr::Token.subtraction("-")
		lexer.next.should == Lexr::Token.number(56)
		lexer.next.should == Lexr::Token.right_parenthesis(")")
		lexer.next.should == Lexr::Token.end
	end
end