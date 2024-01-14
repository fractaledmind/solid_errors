# frozen_string_literal: true

require_relative "solid_errors/version"
require_relative "solid_errors/sanitizer"
require_relative "solid_errors/subscriber"
require_relative "solid_errors/backtrace"
require_relative "solid_errors/backtrace_line"
require_relative "solid_errors/engine"

module SolidErrors
  mattr_accessor :connects_to
end
