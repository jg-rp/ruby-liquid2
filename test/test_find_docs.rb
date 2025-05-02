# frozen_string_literal: true

require "test_helper"

class TestFindDocs < Minitest::Test
  def test_find_block_comment_text
    source = <<~LIQUID
      {% doc %}hello{% enddoc %}
      {% if false %}
      {% doc %}
      foo bar
      {% enddoc %}
      {% endif %}
      {% for x in (1..3) %}
      {% if true %}
      {% doc %}goodbye{% enddoc %}
      {% endif %}
      {% endfor %}
      {% doc %}world{% enddoc %}
    LIQUID

    expect = ["hello", "\nfoo bar\n", "goodbye", "world"]
    template = Liquid2.parse(source)
    comment_text = template.docs.map(&:text)

    assert_equal(expect, comment_text)
  end
end
