require "test_helper"

class SolidErrors::ErrorMailerTest < ActionMailer::TestCase
  DeliveryFailed = Class.new(StandardError)

  class FailingDelivery
    def initialize(_settings)
    end

    def deliver!(_mail)
      raise DeliveryFailed, "535 authentication failed"
    end
  end

  ActionMailer::Base.add_delivery_method :failing, FailingDelivery

  test "the error email renders its html part" do
    report_raised_error("oof")

    email = SolidErrors::ErrorMailer.error_occurred(SolidErrors::Occurrence.last)

    assert_includes email.html_part.body.to_s, "oof"
  end

  test "the error email links to the occurrence when the app has a mailer host" do
    report_raised_error("oof")
    occurrence = SolidErrors::Occurrence.last
    ActionMailer::Base.default_url_options = {host: "errors.example.com"}

    email = SolidErrors::ErrorMailer.error_occurred(occurrence)

    url = "http://errors.example.com/solid_errors/#{occurrence.error_id}#occurrence_#{occurrence.id}"
    assert_includes email.html_part.body.to_s, %(href="#{url}")
    assert_includes email.text_part.body.to_s, url
  ensure
    ActionMailer::Base.default_url_options = {}
  end

  test "the subject says when an error was reopened" do
    report_raised_error("oof")
    occurrence = SolidErrors::Occurrence.last

    assert_equal "⚠️ StandardError", SolidErrors::ErrorMailer.error_occurred(occurrence).subject
    assert_equal "⚠️ StandardError (reopened)", SolidErrors::ErrorMailer.error_occurred(occurrence, :reopened).subject
  end

  test "a reopened error is emailed as reopened" do
    with_emails do
      report_raised_error("oof")
      SolidErrors::Error.last.update!(resolved_at: Time.current)

      assert_enqueued_email_with SolidErrors::ErrorMailer, :error_occurred,
        args: ->(args) { args.last == :reopened } do
        report_raised_error("oof")
      end
    end
  end

  test "a failed delivery is recorded without sending another email" do
    with_failing_delivery do
      report_raised_error("oof")

      assert_no_enqueued_emails { perform_enqueued_jobs }
      assert SolidErrors::Error.exists?(exception_class: DeliveryFailed.name)
    end
  end

  test "emails resume for the next error after a failed delivery" do
    with_failing_delivery do
      report_raised_error("oof")
      perform_enqueued_jobs

      assert_enqueued_emails(1) { report_raised_error("argh") }
    end
  end

  private

  def report_raised_error(message)
    raise StandardError, message
  rescue => error
    Rails.error.report(error)
  end

  def with_emails
    SolidErrors.send_emails = true
    SolidErrors.email_to = "ops@example.com"
    yield
  ensure
    SolidErrors.send_emails = false
    SolidErrors.email_to = nil
  end

  def with_failing_delivery
    delivery_method = ActionMailer::Base.delivery_method
    ActionMailer::Base.delivery_method = :failing
    with_emails { yield }
  ensure
    ActionMailer::Base.delivery_method = delivery_method
  end
end
