require "test_helper"

class SolidErrors::ErrorToMarkdownTest < ActiveSupport::TestCase
  setup do
    begin
      raise StandardError, "Something went wrong"
    rescue => e
      Rails.error.report(e)
    end
    @error = SolidErrors::Error.last
  end

  test "includes exception class and message" do
    result = @error.to_markdown

    assert_includes result, "## Exception: StandardError"
    assert_includes result, "### Message\nSomething went wrong"
    assert_includes result, "**Severity:**"
    assert_includes result, "**Source:**"
  end

  test "includes backtrace when occurrence exists" do
    result = @error.to_markdown

    assert_includes result, "### Backtrace"
  end

  test "includes source context for application lines" do
    occurrence = @error.occurrences.order(created_at: :desc).first
    backtrace = occurrence.parsed_backtrace

    skip "No application lines in test backtrace" unless backtrace.application_lines.any?

    result = @error.to_markdown
    assert_includes result, "### Source Context"
    assert_includes result, "```ruby"
  end

  test "includes request context when present" do
    occurrence = @error.occurrences.order(created_at: :desc).first
    occurrence.update!(context: {"controller" => "UsersController", "action" => "show"})

    result = @error.to_markdown

    assert_includes result, "### Request Context"
    assert_includes result, "- controller: UsersController"
    assert_includes result, "- action: show"
  end

  test "handles error with no occurrences" do
    @error.occurrences.destroy_all

    result = @error.to_markdown

    assert_includes result, "## Exception: StandardError"
    assert_includes result, "### Message\nSomething went wrong"
    refute_includes result, "### Backtrace"
    refute_includes result, "### Source Context"
    refute_includes result, "### Request Context"
  end
end
