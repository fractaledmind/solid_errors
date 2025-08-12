# frozen_string_literal: true

require_relative "solid_errors/version"
require_relative "solid_errors/sanitizer"
require_relative "solid_errors/subscriber"
require_relative "solid_errors/engine"

module SolidErrors
  mattr_accessor :connects_to
  mattr_accessor :full_backtrace
  mattr_accessor :base_controller_class, default: "::ActionController::Base"
  mattr_writer :username
  mattr_writer :password
  mattr_accessor :send_emails, default: false
  mattr_accessor :email_from, default: "solid_errors@noreply.com"
  mattr_accessor :email_to
  mattr_accessor :email_subject_prefix
  mattr_accessor :destroy_after

  class << self
    # use method instead of attr_accessor to ensure
    # this works if variable set after SolidErrors is loaded
    def full_backtrace?
      @full_backtrace ||= ENV["SOLIDERRORS_FULL_BACKTRACE"] || @@full_backtrace || false
    end

    # use method instead of attr_accessor to ensure
    # this works if variable set after SolidErrors is loaded
    # this works if ENV variable set after SolidErrors is loaded
    def username
      @username ||= ENV["SOLIDERRORS_USERNAME"] || @@username
    end

    # use method instead of attr_accessor to ensure
    # this works if ENV variable set after SolidErrors is loaded
    def password
      @password ||= ENV["SOLIDERRORS_PASSWORD"] || @@password
    end

    def send_emails?
      send_emails && email_to.present?
    end
  end
end
