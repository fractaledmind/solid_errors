require "test_helper"

class SolidErrors::ErrorMailerTest < ActionMailer::TestCase
  test "the error email renders its html part" do
    report_raised_error("oof")

    email = SolidErrors::ErrorMailer.error_occurred(SolidErrors::Occurrence.last)

    assert_includes email.html_part.body.to_s, "oof"
  end

  private

  def report_raised_error(message)
    raise StandardError, message
  rescue => error
    Rails.error.report(error)
  end
end
