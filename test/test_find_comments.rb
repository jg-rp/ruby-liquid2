# frozen_string_literal: true

require "test_helper"

class TestFindComments < Minitest::Test
  def test_find_block_comment_text
    source = <<~LIQUID
      {% comment %}hello{% endcomment %}
      {% if false %}
      {% comment %}
      foo bar
      {% endcomment %}
      {% endif %}
      {% for x in (1..3) %}
      {% if true %}
      {% comment %}goodbye{% endcomment %}
      {% endif %}
      {% endfor %}
      {% comment %}world{% endcomment %}
    LIQUID

    expect = ["hello", "\nfoo bar\n", "goodbye", "world"]
    template = Liquid2.parse(source)
    comment_text = template.comments.map(&:text)

    assert_equal(expect, comment_text)
  end

  def test_find_inline_comment_text
    source = <<~LIQUID
      {% # hello %}
      {% if false %}
      {% #
      # foo bar
      # foo bar
      %}
      {% endif %}
      {% for x in (1..3) %}
      {% if true %}
      {% # goodbye %}
      {% endif %}
      {% endfor %}
      {% # world %}
    LIQUID

    expect = [" hello ", "\n# foo bar\n# foo bar\n", " goodbye ", " world "]
    template = Liquid2.parse(source)
    comment_text = template.comments.map(&:text)

    assert_equal(expect, comment_text)
  end

  def test_find_hash_comment_text
    source = <<~LIQUID
      {# hello #}
      {% if false %}
      {#
      # foo bar
      # foo bar
      #}
      {% endif %}
      {% for x in (1..3) %}
      {% if true %}
      {# goodbye #}
      {% endif %}
      {% endfor %}
      {# world #}
    LIQUID

    expect = [" hello ", "\n# foo bar\n# foo bar\n", " goodbye ", " world "]
    template = Liquid2.parse(source)
    comment_text = template.comments.map(&:text)

    assert_equal(expect, comment_text)
  end
end
