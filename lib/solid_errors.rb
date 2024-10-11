# frozen_string_literal: true

require_relative "solid_errors/version"
require_relative "solid_errors/sanitizer"
require_relative "solid_errors/subscriber"
require_relative "solid_errors/engine"

module SolidErrors
  mattr_accessor :connects_to
  mattr_writer :username
  mattr_writer :password
  mattr_writer :send_emails
  mattr_writer :email_from
  mattr_writer :email_to
  mattr_writer :subject_prefix

  class << self
    # use method instead of attr_accessor to ensure
    # this works if variable set after SolidErrors is loaded
    def username
      @username ||= ENV["SOLIDERRORS_USERNAME"] || @@username
    end

    # use method instead of attr_accessor to ensure
    # this works if variable set after SolidErrors is loaded
    def password
      @password ||= ENV["SOLIDERRORS_PASSWORD"] || @@password
    end

    def send_emails?
      @send_emails ||= ENV["SOLIDERRORS_SEND_EMAILS"] || @@send_emails || false
    end

    def email_from
      @email_from ||= ENV["SOLIDERRORS_EMAIL_FROM"] || @@email_from || "solid_errors@noreply.com"
    end

    def email_to
      @email_to ||= ENV["SOLIDERRORS_EMAIL_TO"] || @@email_to
    end

    def subject_prefix
      @subject_prefix ||= ENV["SOLIDERRORS_SUBJECT_PREFIX"] || @@subject_prefix
    end
  end
end
