require "test_helper"

class SolidErrors::EmailConfigurationTest < ActiveSupport::TestCase
  SETTINGS = %i[send_emails email_from email_to email_subject_prefix]
  ENV_VARS = %w[SOLIDERRORS_SEND_EMAILS SOLIDERRORS_EMAIL_FROM SOLIDERRORS_EMAIL_TO SOLIDERRORS_EMAIL_SUBJECT_PREFIX]

  setup do
    @settings = SETTINGS.to_h { |name| [name, SolidErrors.class_variable_get(:"@@#{name}")] }
    @env = ENV.to_h.slice(*ENV_VARS)
    SETTINGS.each { |name| SolidErrors.public_send(:"#{name}=", nil) }
  end

  teardown do
    @settings.each { |name, value| SolidErrors.public_send(:"#{name}=", value) }
    ENV_VARS.each { |var| ENV.delete(var) }
    ENV.update(@env)
  end

  test "email settings fall back to their environment variables" do
    ENV.update(
      "SOLIDERRORS_SEND_EMAILS" => "true",
      "SOLIDERRORS_EMAIL_FROM" => "errors@example.com",
      "SOLIDERRORS_EMAIL_TO" => "devs@example.com",
      "SOLIDERRORS_EMAIL_SUBJECT_PREFIX" => "[App]"
    )

    assert_equal [true, "errors@example.com", "devs@example.com", "[App]"],
      SETTINGS.map { |name| SolidErrors.public_send(name) }
    assert SolidErrors.send_emails?
  end

  test "configured email settings win over their environment variables" do
    ENV.update("SOLIDERRORS_SEND_EMAILS" => "true", "SOLIDERRORS_EMAIL_FROM" => "env@example.com")
    SolidErrors.send_emails = false
    SolidErrors.email_from = "config@example.com"

    assert_equal [false, "config@example.com"], [SolidErrors.send_emails, SolidErrors.email_from]
  end

  test "email settings keep their defaults when neither is set" do
    assert_equal [false, "solid_errors@noreply.com", nil, nil],
      SETTINGS.map { |name| SolidErrors.public_send(name) }
  end
end
