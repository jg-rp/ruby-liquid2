# frozen_string_literal: true

require "test_helper"

class TestCustomDelimiters < Minitest::Test
  make_my_diffs_pretty!

  def test_change_delimiters
    source = <<~LIQUID.chomp
      [% if true %]Hello, [[ you ]]![% endif %]
      [% raw %][[ you ]]![% endraw %]
      [% comment %]
        this is a comment
      [% endcomment %]
      [% # this is an inline comment %]
      [% doc %]
        this is a doc comment
      [% enddoc %]
      [% liquid
        # some comment
        assign x = 42
      %]
      [[ x ]]
    LIQUID

    env = Liquid2::Environment.new(
      markup_out_start: "[[",
      markup_out_end: "]]",
      markup_tag_start: "[%",
      markup_tag_end: "%]",
      markup_comment_prefix: "[#",
      markup_comment_suffix: "]"
    )

    data = { "you" => "World" }

    assert_equal("Hello, World!\n[[ you ]]!\n\n\n\n\n42", env.render(source, data))
  end

  def test_longer_output_delimiters
    source = <<~LIQUID.chomp
      [% if true %]Hello, [[[ you ]]]![% endif %]
      [% liquid
        # some comment
        assign x = 42
      %]
      [[[ x ]]]
    LIQUID

    env = Liquid2::Environment.new(
      markup_out_start: "[[[",
      markup_out_end: "]]]",
      markup_tag_start: "[%",
      markup_tag_end: "%]",
      markup_comment_prefix: "[#",
      markup_comment_suffix: "]"
    )

    data = { "you" => "World" }

    assert_equal("Hello, World!\n\n42", env.render(source, data))
  end

  def test_two_environments_with_different_delimiters
    source = "Hello, [[ you ]]!"

    env = Liquid2::Environment.new(
      markup_out_start: "[[",
      markup_out_end: "]]"
    )

    another_source = "Hello, (( you ))!"

    another_env = Liquid2::Environment.new(
      markup_out_start: "((",
      markup_out_end: "))"
    )

    data = { "you" => "World" }

    assert_equal("Hello, World!", env.render(source, data))
    assert_equal("Hello, World!", another_env.render(another_source, data))
  end
end
