# frozen_string_literal: true

require_relative "solid_errors/version"
require_relative "solid_errors/sanitizer"
require_relative "solid_errors/subscriber"
require_relative "solid_errors/engine"

module SolidErrors
  mattr_accessor :enabled, default: true
  mattr_accessor :connects_to
  mattr_accessor :base_controller_class, default: "::ActionController::Base"
  mattr_writer :username
  mattr_writer :password
  mattr_writer :send_emails, :email_from, :email_to, :email_subject_prefix, default: nil
  mattr_accessor :email_every_occurrence, default: true
  # Builds the error email's subject, before email_subject_prefix. reason is :created or :reopened when
  # the occurrence opened its error, nil for any other occurrence, or the app's own reason when it sends the email itself
  mattr_accessor :email_subject, default: ->(error:, occurrence:, reason:) {
    subject = "#{error.severity_emoji} #{error.exception_class}"
    (reason == :reopened) ? "#{subject} (reopened)" : subject
  }
  mattr_accessor :destroy_after
  mattr_accessor :ignored_errors, default: []
  # What an error is grouped by: occurrences whose text is the same are one error. Called with the exception and the
  # attributes stored for it; the default is the class, message, severity and source, as every version before it
  mattr_accessor :fingerprint, default: ->(error:, attributes:) {
    attributes.values_at(:exception_class, :message, :severity, :source).join
  }
  # Request params and job arguments carry user content that filter_parameters' key matching misses
  mattr_accessor :record_params, default: false
  mattr_accessor :record_arguments, default: false
  mattr_writer :url_helper_name, :url_options

  class << self
    # use method instead of attr_accessor to ensure
    # this works if ENV variable set after SolidErrors is loaded
    def username
      @username ||= ENV["SOLIDERRORS_USERNAME"] || @@username
    end

    # use method instead of attr_accessor to ensure
    # this works if ENV variable set after SolidErrors is loaded
    def password
      @password ||= ENV["SOLIDERRORS_PASSWORD"] || @@password
    end

    # Each email setting falls back to its SOLIDERRORS_* environment variable when not configured
    def send_emails
      @@send_emails.nil? ? ActiveModel::Type::Boolean.new.cast(ENV["SOLIDERRORS_SEND_EMAILS"]) || false : @@send_emails
    end

    def email_from
      @@email_from || ENV["SOLIDERRORS_EMAIL_FROM"] || "solid_errors@noreply.com"
    end

    def email_to
      @@email_to || ENV["SOLIDERRORS_EMAIL_TO"]
    end

    def email_subject_prefix
      @@email_subject_prefix || ENV["SOLIDERRORS_EMAIL_SUBJECT_PREFIX"]
    end

    # Whether the errors database has every table and column this version reads and writes.
    # Assert it in your test suite to catch a schema change you haven't applied yet.
    def migrated?
      {
        SolidErrors::Error => %w[exception_class message severity source resolved_at fingerprint created_at updated_at],
        SolidErrors::Occurrence => %w[error_id backtrace context created_at updated_at]
      }.all? do |model, columns|
        model.table_exists? && (columns - model.column_names).empty?
      end
    end

    def send_emails?
      send_emails && email_to.present? && !ActiveSupport::IsolatedExecutionState[:solid_errors_without_emails]
    end

    # Errors reported inside the block are recorded but never emailed
    def without_emails
      previous = ActiveSupport::IsolatedExecutionState[:solid_errors_without_emails]
      ActiveSupport::IsolatedExecutionState[:solid_errors_without_emails] = true
      yield
    ensure
      ActiveSupport::IsolatedExecutionState[:solid_errors_without_emails] = previous
    end

    def url_helper_name
      @@url_helper_name ||= detect_url_helper_name
    end

    def url_options
      @@url_options ||= detect_url_options
    end

    private

    def find_solid_errors_route
      @solid_errors_route ||= Rails.application.routes.routes.find do |r|
        r.name&.to_s&.end_with?("solid_errors")
      end
    end

    def detect_url_helper_name
      find_solid_errors_route&.name&.to_sym || :solid_errors
    end

    def detect_url_options
      subdomain = find_solid_errors_route&.constraints&.dig(:subdomain)
      subdomain.is_a?(String) ? {subdomain: subdomain} : {}
    end
  end
end
