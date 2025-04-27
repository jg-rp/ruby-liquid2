# frozen_string_literal: true

require "test_helper"

class TestTokenize < Minitest::Spec
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
      want: [[:token_other, "Hello, World!", 0]]
    },
    {
      name: "just whitespace",
      source: " \n ",
      want: [[:token_other, " \n ", 0]]
    },
    {
      name: "just output",
      source: "{{ hello }}",
      want: [
        [:token_output_start, nil, 0],
        [:token_word, "hello", 3],
        [:token_output_end, nil, 9]
      ]
    },
    {
      name: "hello liquid",
      source: "Hello, {{ you }}!",
      want: [
        [:token_other, "Hello, ", 0],
        [:token_output_start, nil, 7],
        [:token_word, "you", 10],
        [:token_output_end, nil, 14],
        [:token_other, "!", 16]
      ]
    },
    {
      name: "output, filter, integer literals",
      source: "{{ 42 | plus: 3 }}",
      want: [
        [:token_output_start, nil, 0],
        [:token_int, "42", 3],
        [:token_pipe, nil, 6],
        [:token_word, "plus", 8],
        [:token_colon, nil, 12],
        [:token_int, "3", 14],
        [:token_output_end, nil, 16]
      ]
    },
    {
      name: "output, filter, float literals",
      source: "{{ 42.2 | minus: 3.0 }}",
      want: [
        [:token_output_start, nil, 0],
        [:token_float, "42.2", 3],
        [:token_pipe, nil, 8],
        [:token_word, "minus", 10],
        [:token_colon, nil, 15],
        [:token_float, "3.0", 17],
        [:token_output_end, nil, 21]
      ]
    },
    {
      name: "output, filter, range literal",
      source: "{{ (1..5) | join: ', ' }}",
      want: [
        [:token_output_start, nil, 0],
        [:token_lparen, nil, 3],
        [:token_int, "1", 4],
        [:token_double_dot, nil, 5],
        [:token_int, "5", 7],
        [:token_rparen, nil, 8],
        [:token_pipe, nil, 10],
        [:token_word, "join", 12],
        [:token_colon, nil, 16],
        [:token_single_quote_string, ", ", 19],
        [:token_output_end, nil, 23]
      ]
    },
    {
      name: "string, single quote, escape sequence",
      source: "{{ 'Hello\\n, world' }}",
      want: [
        [:token_output_start, nil, 0],
        [:token_single_quote_string, "Hello\n, world", 4],
        [:token_output_end, nil, 20]

      ]
    },
    {
      name: "string, double quote, escape sequence",
      source: "{{ \"Hello\\n, world\" }}",
      want: [
        [:token_output_start, nil, 0],
        [:token_double_quote_string, "Hello\n, world", 4],
        [:token_output_end, nil, 20]

      ]
    }
  ].freeze

  # TODO: finish me

  scanner = StringScanner.new("")

  describe "scan template" do
    TEST_CASES.each do |test_case|
      it test_case[:name] do
        tokens = Liquid2::Scanner.tokenize(test_case[:source], scanner)
        _(tokens).must_equal test_case[:want]
      end
    end
  end
end
