module SolidErrors
  # adapted from: https://github.com/honeybadger-io/honeybadger-ruby/blob/master/lib/honeybadger/backtrace.rb
  class Backtrace
    # Holder for an Array of Backtrace::Line instances.
    attr_reader :lines, :application_lines

    def self.parse(ruby_backtrace, opts = {})
      ruby_lines = ruby_backtrace.to_a

      lines = ruby_lines.collect do |unparsed_line|
        BacktraceLine.parse(unparsed_line.to_s, opts)
      end.compact

      new(lines)
    end

    def initialize(lines)
      self.lines = lines
      self.application_lines = lines.select(&:application?)
    end

    # Convert Backtrace to array.
    #
    # Returns array containing backtrace lines.
    def to_ary
      lines.take(1000).map { |l| {number: l.filtered_number, file: l.filtered_file, method: l.filtered_method, source: l.source} }
    end
    alias_method :to_a, :to_ary

    # JSON support.
    #
    # Returns JSON representation of backtrace.
    def as_json(options = {})
      to_ary
    end

    def to_s
      lines.map(&:to_s).join("\n")
    end

    def inspect
      "<Backtrace: " + lines.collect { |line| line.inspect }.join(", ") + ">"
    end

    private

    attr_writer :lines, :application_lines
  end
end
