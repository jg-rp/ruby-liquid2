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
        [:token_pipe, "|", 6],
        [:token_word, "plus", 8],
        [:token_colon, ":", 12],
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
        [:token_pipe, "|", 8],
        [:token_word, "minus", 10],
        [:token_colon, ":", 15],
        [:token_float, "3.0", 17],
        [:token_output_end, nil, 21]
      ]
    },
    {
      name: "output, filter, range literal",
      source: "{{ (1..5) | join: ', ' }}",
      want: [
        [:token_output_start, nil, 0],
        [:token_lparen, "(", 3],
        [:token_int, "1", 4],
        [:token_double_dot, "..", 5],
        [:token_int, "5", 7],
        [:token_rparen, ")", 8],
        [:token_pipe, "|", 10],
        [:token_word, "join", 12],
        [:token_colon, ":", 16],
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
    },
    {
      name: "comment",
      source: "Hello, {# some comment {{ foo }} #}{{ you }}!",
      want: [
        [:token_other, "Hello, ", 0],
        [:token_comment_start, "{#", 7],
        [:token_comment, " some comment {{ foo }} ", 9],
        [:token_comment_end, "#}", 33],
        [:token_output_start, nil, 35],
        [:token_word, "you", 38],
        [:token_output_end, nil, 42],
        [:token_other, "!", 44]
      ]
    },
    {
      name: "comment with whitespace control",
      source: "Hello, {#- some comment {{ foo }} +#}{{ you }}!",
      want: [
        [:token_other, "Hello, ", 0],
        [:token_comment_start, "{#", 7],
        [:token_whitespace_control, "-", 9],
        [:token_comment, " some comment {{ foo }} ", 10],
        [:token_whitespace_control, "+", 34],
        [:token_comment_end, "#}", 35],
        [:token_output_start, nil, 37],
        [:token_word, "you", 40],
        [:token_output_end, nil, 44],
        [:token_other, "!", 46]
      ]
    },
    {
      name: "comment, nested",
      source: "Hello, {## some comment {# other comment #} ##}{{ you }}!",
      want: [
        [:token_other, "Hello, ", 0],
        [:token_comment_start, "{##", 7],
        [:token_comment, " some comment {# other comment #} ", 10],
        [:token_comment_end, "##}", 44],
        [:token_output_start, nil, 47],
        [:token_word, "you", 50],
        [:token_output_end, nil, 54],
        [:token_other, "!", 56]
      ]
    },
    {
      name: "output, plus operator",
      source: "{{ 42 + 3 }}",
      want: [
        [:token_output_start, nil, 0],
        [:token_int, "42", 3],
        [:token_plus, "+", 6],
        [:token_int, "3", 8],
        [:token_output_end, nil, 10]
      ]
    },
    {
      name: "output, minus operator",
      source: "{{ 42 - 3 }}",
      want: [
        [:token_output_start, nil, 0],
        [:token_int, "42", 3],
        [:token_minus, "-", 6],
        [:token_int, "3", 8],
        [:token_output_end, nil, 10]
      ]
    },
    {
      name: "output, modulo operator",
      source: "{{ 42 % 3 }}",
      want: [
        [:token_output_start, nil, 0],
        [:token_int, "42", 3],
        [:token_mod, "%", 6],
        [:token_int, "3", 8],
        [:token_output_end, nil, 10]
      ]
    },
    {
      name: "output, divide operator",
      source: "{{ 42 / 3 }}",
      want: [
        [:token_output_start, nil, 0],
        [:token_int, "42", 3],
        [:token_divide, "/", 6],
        [:token_int, "3", 8],
        [:token_output_end, nil, 10]
      ]
    },
    {
      name: "output, times operator",
      source: "{{ 42 * 3 }}",
      want: [
        [:token_output_start, nil, 0],
        [:token_int, "42", 3],
        [:token_times, "*", 6],
        [:token_int, "3", 8],
        [:token_output_end, nil, 10]
      ]
    },
    {
      name: "output, power operator",
      source: "{{ 42 ** 3 }}",
      want: [
        [:token_output_start, nil, 0],
        [:token_int, "42", 3],
        [:token_pow, "**", 6],
        [:token_int, "3", 9],
        [:token_output_end, nil, 11]
      ]
    },
    {
      name: "output, floor div operator",
      source: "{{ 42 // 3 }}",
      want: [
        [:token_output_start, nil, 0],
        [:token_int, "42", 3],
        [:token_floor_div, "//", 6],
        [:token_int, "3", 9],
        [:token_output_end, nil, 11]
      ]
    }
  ].freeze

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
