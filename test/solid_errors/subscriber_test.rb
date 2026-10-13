require "test_helper"

class SolidErrors::SubscriberTest < ActiveSupport::TestCase
  CustomError = Class.new(StandardError)

  teardown do
    SolidErrors.ignored_errors = []
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
end
