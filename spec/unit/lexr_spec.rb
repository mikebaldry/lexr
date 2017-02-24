require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe "Creating an instance" do
  subject { Lexr.new("test", [123]) }
  it "should store the parameters and initialize the position" do
    expect(subject.instance_variable_get(:@text)).to eq("test")
    expect(subject.instance_variable_get(:@position)).to eq(0)
    expect(subject.instance_variable_get(:@current)).to eq(Lexr::Token.start)
    expect(subject.instance_variable_get(:@rules)).to eq([123])
  end

  it "should not be at the end" do
    expect(subject).to_not be_end
  end
end

describe "Peeking the next token" do
  subject { Lexr.new("abcd", [Lexr::Rule.new(/[a-z]/, :a_letter)]) }

  it "should return the next token but not advance the string" do
    expect(subject.peek.value).to eq("a")
    expect(subject.peek.value).to eq("a")
    expect(subject.next.value).to eq("a")
    expect(subject.next.value).to eq("b")
  end

  it "should not change the current token" do
    expect(subject.current).to eq(Lexr::Token.start)
    expect(subject.peek.value).to eq("a")
    expect(subject.current).to eq(Lexr::Token.start)
  end

  it "should still peek if we come to an ignored token (bug fix)" do
    subject = Lexr.new("a-b-c", [Lexr::Rule.new("-", :ignore_me, ignore: true),  Lexr::Rule.new(/[a-z]/, :a_letter)])

    expect(subject.peek.value).to eq("a")
    expect(subject.next.value).to eq("a")
    expect(subject.peek.value).to eq("b")
    expect(subject.current.value).to eq("a")
  end
end

describe "Getting the next token" do
  it "should return :end token when all tokens are read" do
    subject = Lexr.new("abc", [])
    subject.instance_eval { @position = 3 }

    expect(subject.next).to eq(Lexr::Token.end)
    expect(subject.current).to eq(Lexr::Token.end)
    expect(subject).to be_end
  end

  it "should advance the string and return the correct token for a matching literal" do
    subject = Lexr.new("ab", [Lexr::Rule.new("a", :an_a)])

    expect(subject.next).to eq(Lexr::Token.an_a("a"))
    expect(subject.current).to eq(Lexr::Token.an_a("a"))
    expect(subject).to_not be_end
    expect(subject.send(:unprocessed_text)).to eq("b")
  end

  it "should advance the string and return the correct token for a matching regex" do
    subject = Lexr.new("ab", [Lexr::Rule.new(/[a-z]/, :a_letter)])
    expect(subject.next).to eq(Lexr::Token.a_letter("a"))
    expect(subject.send(:unprocessed_text)).to eq("b")
  end

  it "should use the conversion block to convert a string result into another type" do
    subject = Lexr.new("ab", [Lexr::Rule.new(/[a-z]/, :a_letter, convert_with: lambda { |v| 123 })])

    expect(subject.next).to eq(Lexr::Token.a_letter(123))
    expect(subject.current).to eq(Lexr::Token.a_letter(123))
    expect(subject).to_not be_end
  end

  it "should match and advance but not return the token (should return the next token after it) when using ignore" do
    subject = Lexr.new("a1", [Lexr::Rule.new(/[a-z]/, :a_letter, ignore: true),
                              Lexr::Rule.new(/[0-9]/, :a_number)])

    expect(subject.next).to eq(Lexr::Token.a_number("1"))
  end

  it "should raise an error if it is unable to match a rule" do
    subject = Lexr.new(":1", [Lexr::Rule.new("1", :an_a)])

    expect { subject.next }.to raise_error(Lexr::UnmatchableTextError, "Unexpected character ':' at position 1")
  end

  it "should work correctly with multiline tokens inverse test" do
    subject = Lexr.new("this-and-that-and-this-and-that", [Lexr::Rule.new(/this-and-that/, :this_and_that),
                                                                 Lexr::Rule.new("-and-", :and)])

    expect(subject.next).to eq(Lexr::Token.this_and_that("this-and-that"))
    expect(subject.next).to eq(Lexr::Token.and("-and-"))
    expect(subject.next).to eq(Lexr::Token.this_and_that("this-and-that"))
  end

  it "should work correctly with multiline string tokens" do
    subject = Lexr.new("this\nand\nthat\nand\nthis\nand\nthat", [Lexr::Rule.new("this\nand\nthat", :this_and_that),
                                                                 Lexr::Rule.new("\nand\n", :and)])

    expect(subject.next).to eq(Lexr::Token.this_and_that("this\nand\nthat"))
    expect(subject.next).to eq(Lexr::Token.and("\nand\n"))
    expect(subject.next).to eq(Lexr::Token.this_and_that("this\nand\nthat"))
  end

  it "should work correctly with multiline regex tokens" do
    subject = Lexr.new("this\nand\nthat\nand\nthis\nand\nthat", [Lexr::Rule.new(/this\nand\nthat/, :this_and_that),
                                                                 Lexr::Rule.new("\nand\n", :and)])

    expect(subject.next).to eq(Lexr::Token.this_and_that("this\nand\nthat"))
    expect(subject.next).to eq(Lexr::Token.and("\nand\n"))
    expect(subject.next).to eq(Lexr::Token.this_and_that("this\nand\nthat"))
  end
end

describe "A pretty dsl" do
  it "should store a basic rule entered with the correct values and no options" do
    subject = Lexr.that {
      matches "abc" => :mj
    }
    rules = subject.instance_eval { @rules }

    expect(rules.first).to eq(Lexr::Rule.new("abc", :mj))
  end

  it "should store a rule with options correctly" do
    subject = Lexr.that {
      matches /[0-9]+/ => :number, convert: :test
    }
    rules = subject.instance_eval { @rules }

    expect(rules.first).to eq(Lexr::Rule.new(/[0-9]+/, :number, convert: :test))
  end

  it "should store an ignore rule correctly" do
    subject = Lexr.that {
      ignores /\s+/ => :whitespace
    }
    rules = subject.instance_eval { @rules }
    expect(rules.first).to eq(Lexr::Rule.new(/\s+/, :whitespace, ignore: true))
  end

  it "should create instances of a Lexr containing the correct rules and text" do
    subject = Lexr.that {
      matches /[0-9]+/ => :number, :convert => :test
      ignores /\s+/ => :whitespace
    }.new(" 123  ")

    expect(subject.instance_eval { @text }).to eq(" 123  ")
    expect(subject.instance_eval { @rules }).to eq([
      Lexr::Rule.new(/[0-9]+/, :number, :convert => :test),
      Lexr::Rule.new(/\s+/, :whitespace, :ignore => true)
    ])
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

    expect(lexer.next).to eq(Lexr::Token.number(1))
    expect(lexer.next).to eq(Lexr::Token.multiplication("*"))
    expect(lexer.next).to eq(Lexr::Token.number(12.5))
    expect(lexer.next).to eq(Lexr::Token.division("/"))
    expect(lexer.next).to eq(Lexr::Token.left_parenthesis("("))
    expect(lexer.next).to eq(Lexr::Token.number(55))
    expect(lexer.next).to eq(Lexr::Token.addition("+"))
    expect(lexer.next).to eq(Lexr::Token.number(2))
    expect(lexer.next).to eq(Lexr::Token.subtraction("-"))
    expect(lexer.next).to eq(Lexr::Token.number(56))
    expect(lexer.next).to eq(Lexr::Token.right_parenthesis(")"))
    expect(lexer.next).to eq(Lexr::Token.end)
  end
end

describe "Conditional matching" do
  it "should understand binary/unary operators correctly, given the predecate to decide" do
    subject = Lexr.that {
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

    lexer = subject.new("-10*(-3--2)")
    expect(lexer.next).to eq(Lexr::Token.number(-10))
    expect(lexer.next).to eq(Lexr::Token.multiplication("*"))

    expect(lexer.next).to eq(Lexr::Token.left_parenthesis("("))
    expect(lexer.next).to eq(Lexr::Token.number(-3))
    expect(lexer.next).to eq(Lexr::Token.subtraction("-"))
    expect(lexer.next).to eq(Lexr::Token.number(-2))
    expect(lexer.next).to eq(Lexr::Token.right_parenthesis(")"))

    expect(lexer.next).to eq(Lexr::Token.end)
  end
end
