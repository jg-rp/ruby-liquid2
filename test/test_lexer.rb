# frozen_string_literal: true

require "test_helper"

Token = Liquid2::Token

class TestLexerTokens < Minitest::Spec
  make_my_diffs_pretty!

  TEST_CASES = [
    {
      name: "empty",
      source: "",
      want: []
    },
    {
      name: "no markup",
      source: "Hello, World!",
      want: [Token.new(:token_other, 0, "", "Hello, World!")]
    },
    {
      name: "just whitespace",
      source: " \n ",
      want: [Token.new(:token_other, 0, "", " \n ")]
    },
    {
      name: "just output",
      source: "{{ hello }}",
      want: [
        Token.new(:token_output_start, 0, "", "{{"),
        Token.new(:token_word, 3, " ", "hello"),
        Token.new(:token_output_end, 9, " ", "}}")
      ]
    },
    {
      name: "hello liquid",
      source: "Hello, {{ you }}!",
      want: [
        Token.new(:token_other, 0, "", "Hello, "),
        Token.new(:token_output_start, 7, "", "{{"),
        Token.new(:token_word, 10, " ", "you"),
        Token.new(:token_output_end, 14, " ", "}}"),
        Token.new(:token_other, 16, "", "!")
      ]
    },
    {
      name: "output, filter, integer literals",
      source: "{{ 42 | plus: 3 }}",
      want: [
        Token.new(:token_output_start, 0, "", "{{"),
        Token.new(:token_int, 3, " ", "42"),
        Token.new(:token_pipe, 6, " ", "|"),
        Token.new(:token_word, 8, " ", "plus"),
        Token.new(:token_colon, 12, "", ":"),
        Token.new(:token_int, 14, " ", "3"),
        Token.new(:token_output_end, 16, " ", "}}")
      ]
    },
    {
      name: "output, filter, float literals",
      source: "{{ 42.2 | minus: 3.0 }}",
      want: [
        Token.new(:token_output_start, 0, "", "{{"),
        Token.new(:token_float, 3, " ", "42.2"),
        Token.new(:token_pipe, 8, " ", "|"),
        Token.new(:token_word, 10, " ", "minus"),
        Token.new(:token_colon, 15, "", ":"),
        Token.new(:token_float, 17, " ", "3.0"),
        Token.new(:token_output_end, 21, " ", "}}")
      ]
    },
    {
      name: "output, filter, range literal",
      source: "{{ (1..5) | join: ', ' }}",
      want: [
        Token.new(:token_output_start, 0, "", "{{"),
        Token.new(:token_lparen, 3, " ", "("),
        Token.new(:token_int, 4, "", "1"),
        Token.new(:token_double_dot, 5, "", ".."),
        Token.new(:token_int, 7, "", "5"),
        Token.new(:token_rparen, 8, "", ")"),
        Token.new(:token_pipe, 10, " ", "|"),
        Token.new(:token_word, 12, " ", "join"),
        Token.new(:token_colon, 16, "", ":"),
        Token.new(:token_single_quote, 18, " ", "'"),
        Token.new(:token_string, 19, "", ", "),
        Token.new(:token_single_quote, 21, "", "'"),
        Token.new(:token_output_end, 23, " ", "}}")
      ]
    }
  ].freeze

  describe "tokenize template" do
    TEST_CASES.each do |test_case|
      it test_case[:name] do
        tokens = Liquid2.tokenize(test_case[:source])
        _(tokens).must_equal test_case[:want]
      end
    end
  end
end

# These tests are lazy in that I can't be bothered to type out `Token.new` for each token.
class TestLexer < Minitest::Spec
  make_my_diffs_pretty!

  TEST_CASES = [
    {
      name: "raw",
      source: "Hello, {% raw %}{{ you }}{% endraw %}!",
      want: [
        "Hello, ",
        "{%",
        " raw",
        " %}",
        "{{ you }}",
        "{%",
        " endraw",
        " %}",
        "!"
      ]
    },
    {
      name: "raw, whitespace control",
      source: "Hello, {%- raw +%}{{ you }}{%~ endraw -%}!",
      want: [
        "Hello, ",
        "{%",
        "-",
        " raw",
        " +",
        "%}",
        "{{ you }}",
        "{%",
        "~",
        " endraw",
        " -",
        "%}",
        "!"
      ]
    },
    {
      name: "output, whitespace control",
      source:
        "Hello, {{- you -}}, {{+ you +}}, {{~ you ~}}, {{+ you -}}, {{~ you -}}, {{- you +}}!",
      want: [
        "Hello, ",
        "{{",
        "-",
        " you",
        " -",
        "}}",
        ", ",
        "{{",
        "+",
        " you",
        " +",
        "}}",
        ", ",
        "{{",
        "~",
        " you",
        " ~",
        "}}",
        ", ",
        "{{",
        "+",
        " you",
        " -",
        "}}",
        ", ",
        "{{",
        "~",
        " you",
        " -",
        "}}",
        ", ",
        "{{",
        "-",
        " you",
        " +",
        "}}",
        "!"
      ]
    },
    {
      name: "assign tag",
      source: "{% assign x = true %}",
      want: ["{%", " assign", " x", " =", " true", " %}"]
    },
    {
      name: "string, escape sequence",
      source: "{{ 'Hello\\n, world' }}",
      want: ["{{", " '", "Hello", "\\n", ", world", "'", " }}"]
    },
    {
      name: "template string, single quote",
      source: "{{ 'Hello, ${you}!' }}",
      want: ["{{", " '", "Hello, ", "${", "you", "}", "!", "'", " }}"]
    },
    {
      name: "template string with filter",
      source: "{{ 'Hello, ${you | upcase}!' }}",
      want: [
        "{{",
        " '",
        "Hello, ",
        "${",
        "you",
        " |",
        " upcase",
        "}",
        "!",
        "'",
        " }}"
      ]
    },
    {
      name: "template string, just a placeholder",
      source: "{{ '${you}' }}",
      want: ["{{", " '", "${", "you", "}", "'", " }}"]
    },
    {
      name: "lambda expression",
      source: "{% assign x = a | map: i => i.foo.bar %}",
      want: [
        "{%",
        " assign",
        " x",
        " =",
        " a",
        " |",
        " map",
        ":",
        " i",
        " =>",
        " i",
        ".",
        "foo",
        ".",
        "bar",
        " %}"
      ]
    },
    {
      name: "comment",
      source: "{# some comment #}",
      want: ["{#", " some comment ", "#}"]
    },
    {
      name: "liquid, one line",
      source: "{% liquid echo 'Hello, World!' %}",
      want: ["{%", " liquid", " echo", " '", "Hello, World!", "'", " %}"]
    },
    {
      name: "liquid, leading newline",
      source: "{% liquid\necho 'Hello, World!' %}",
      want: ["{%", " liquid", "\necho", " '", "Hello, World!", "'", " %}"]
    },
    {
      name: "liquid, multi-line",
      source: "{% liquid\nif true\necho 'Hello, World!'\nendif %}",
      want: ["{%", " liquid", "\nif", " true", "\n", "echo", " '", "Hello, World!", "'", "\n",
             "endif", " %}"]
    }
  ].freeze

  describe "tokenize template" do
    TEST_CASES.each do |test_case|
      it test_case[:name] do
        tokens = Liquid2.tokenize(test_case[:source])
        token_text = tokens.map(&:full_text)
        full_text = token_text.join
        _(full_text).must_equal test_case[:source]
        _(token_text).must_equal test_case[:want]
      end
    end
  end
end
