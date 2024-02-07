# frozen_string_literal: true

require_relative "solid_errors/version"
require_relative "solid_errors/sanitizer"
require_relative "solid_errors/subscriber"
require_relative "solid_errors/engine"
require_relative "solid_errors/railtie"

module SolidErrors
  mattr_accessor :connects_to
  mattr_writer :username
  mattr_writer :password

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
  end
end
