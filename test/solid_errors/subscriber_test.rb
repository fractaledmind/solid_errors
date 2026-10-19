require "test_helper"

class SolidErrors::SubscriberTest < ActiveSupport::TestCase
  CustomError = Class.new(StandardError)

  setup do
    @default_fingerprint = SolidErrors.fingerprint
  end

  teardown do
    SolidErrors.ignored_errors = []
    SolidErrors.fingerprint = @default_fingerprint
  end

  test "errors named in ignored_errors are not recorded while others are" do
    SolidErrors.ignored_errors = [CustomError.name]

    Rails.error.report(CustomError.new("ignored"))
    Rails.error.report(StandardError.new("recorded"))

    assert_equal ["StandardError"], SolidErrors::Error.pluck(:exception_class)
  end

  test "ignored_errors accepts classes as well as names" do
    SolidErrors.ignored_errors = [CustomError]

    Rails.error.report(CustomError.new("ignored"))

    assert_empty SolidErrors::Error.all
  end

  test "the built-in ignored errors still apply alongside ignored_errors" do
    SolidErrors.ignored_errors = [CustomError.name]

    Rails.error.report(ActiveRecord::RecordNotFound.new("ignored"))

    assert_empty SolidErrors::Error.all
  end

  test "the default fingerprint is the one earlier versions computed, so upgrading regroups nothing" do
    Rails.error.report(StandardError.new("boom"), severity: :error, source: "application.job")

    expected = Digest::SHA256.hexdigest(["StandardError", "boom", "error", "application.job"].join)
    assert_equal expected, SolidErrors::Error.sole.fingerprint
  end

  test "a fingerprint proc groups messages that differ only in an id, and keeps each message as reported" do
    SolidErrors.fingerprint = ->(error:, attributes:) {
      attributes.merge(message: attributes[:message].gsub(/\breq_\w+/, "req_*")).values.join
    }

    Rails.error.report(StandardError.new("upstream failed (req_abc123)"))
    Rails.error.report(StandardError.new("upstream failed (req_def456)"))
    Rails.error.report(StandardError.new("something else failed (req_abc123)"))

    errors = SolidErrors::Error.order(:id).map { |error| [error.message, error.occurrences.count] }
    assert_equal [["upstream failed (req_abc123)", 2], ["something else failed (req_abc123)", 1]], errors
  end

  test "each occurrence keeps the message it was raised with, which a grouped error does not" do
    SolidErrors.fingerprint = ->(error:, attributes:) {
      attributes.merge(message: attributes[:message].gsub(/\breq_\w+/, "req_*")).values.join
    }

    Rails.error.report(StandardError.new("upstream failed (req_abc123)"))
    Rails.error.report(StandardError.new("upstream failed (req_def456)"))

    messages = SolidErrors::Error.sole.occurrences.order(:id).map { |occurrence| occurrence.context["message"] }
    assert_equal ["upstream failed (req_abc123)", "upstream failed (req_def456)"], messages
  end

  test "an occurrence records its message whether or not anything is grouped" do
    Rails.error.report(StandardError.new("plain failure"))

    assert_equal "plain failure", SolidErrors::Occurrence.sole.context["message"]
  end

  test "a message the app put in the context is the one kept" do
    Rails.error.report(StandardError.new("raised"), context: {message: "the app said"})

    assert_equal "the app said", SolidErrors::Occurrence.sole.context["message"]
  end

  test "the fingerprint proc is given the exception" do
    SolidErrors.fingerprint = ->(error:, attributes:) { error.class.name }

    Rails.error.report(CustomError.new("one"))
    Rails.error.report(CustomError.new("two"))

    assert_equal 2, SolidErrors::Error.sole.occurrences.count
  end
end
