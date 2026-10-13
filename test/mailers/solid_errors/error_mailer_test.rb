require "test_helper"

class SolidErrors::ErrorMailerTest < ActionMailer::TestCase
  test "the error email renders its html part" do
    Rails.error.report(StandardError.new("oof"))

    email = SolidErrors::ErrorMailer.error_occurred(SolidErrors::Occurrence.last)

    assert_includes email.html_part.body.to_s, "oof"
  end
end
