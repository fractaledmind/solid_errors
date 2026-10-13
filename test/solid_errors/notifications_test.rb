require "test_helper"

class SolidErrors::NotificationsTest < ActiveSupport::TestCase
  test "a new error publishes error_created and occurrence_created" do
    events = capture_events { report_raised_error("oof") }

    error = SolidErrors::Error.last
    occurrence = SolidErrors::Occurrence.last
    assert_equal %w[error_created occurrence_created], events.map(&:first).sort
    events.each { |_name, payload| assert_equal [error, occurrence], payload.values_at(:error, :occurrence) }
  end

  test "a repeat of an unresolved error publishes only occurrence_created" do
    report_raised_error("oof")

    events = capture_events { report_raised_error("oof") }

    assert_equal %w[occurrence_created], events.map(&:first)
  end

  test "a resolved error that occurs again publishes error_reopened and occurrence_created" do
    report_raised_error("oof")
    SolidErrors::Error.last.update!(resolved_at: Time.current)

    events = capture_events { report_raised_error("oof") }

    assert_equal %w[error_reopened occurrence_created], events.map(&:first).sort
  end

  test "resolving an error publishes error_resolved" do
    report_raised_error("oof")
    error = SolidErrors::Error.last

    events = capture_events { error.update!(resolved_at: Time.current) }

    assert_equal [["error_resolved", {error: error}]], events
  end

  test "updating a resolved error without changing its resolution publishes nothing" do
    report_raised_error("oof")
    error = SolidErrors::Error.last
    error.update!(resolved_at: Time.current)

    events = capture_events { error.update!(message: "changed") }

    assert_empty events
  end

  private

  def capture_events(&block)
    events = []
    callback = ->(name, _start, _finish, _id, payload) { events << [name.delete_suffix(".solid_errors"), payload] }
    ActiveSupport::Notifications.subscribed(callback, /\.solid_errors\z/, &block)
    events
  end

  def report_raised_error(message)
    raise StandardError, message
  rescue => error
    Rails.error.report(error)
  end
end
