require "test_helper"

class SolidErrors::EmailNotificationsTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    SolidErrors.send_emails = true
    SolidErrors.email_to = "ops@example.com"
  end

  teardown do
    SolidErrors.send_emails = false
    SolidErrors.email_to = nil
    SolidErrors.email_every_occurrence = true
  end

  test "every occurrence is emailed by default" do
    report_raised_error("oof")

    assert_enqueued_emails(1) { report_raised_error("oof") }
  end

  test "a new error is emailed when only new and reopened errors are" do
    SolidErrors.email_every_occurrence = false

    assert_enqueued_emails(1) { report_raised_error("oof") }
  end

  test "a repeat of an unresolved error is not emailed when only new and reopened errors are" do
    SolidErrors.email_every_occurrence = false
    report_raised_error("oof")

    assert_no_enqueued_emails { report_raised_error("oof") }
  end

  test "a resolved error that occurs again is emailed when only new and reopened errors are" do
    SolidErrors.email_every_occurrence = false
    report_raised_error("oof")
    SolidErrors::Error.last.update!(resolved_at: Time.current)

    assert_enqueued_emails(1) { report_raised_error("oof") }
  end

  private

  def report_raised_error(message)
    raise StandardError, message
  rescue => error
    Rails.error.report(error)
  end
end
