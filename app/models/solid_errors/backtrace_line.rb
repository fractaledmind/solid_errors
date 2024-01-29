module SolidErrors
  # adapted from: https://github.com/honeybadger-io/honeybadger-ruby/blob/master/lib/honeybadger/backtrace.rb
  class BacktraceLine
    # Backtrace line regexp (optionally allowing leading X: for windows support).
    INPUT_FORMAT = %r{^((?:[a-zA-Z]:)?[^:]+):(\d+)(?::in `([^']+)')?$}.freeze
    STRING_EMPTY = "".freeze
    GEM_ROOT = "[GEM_ROOT]".freeze
    PROJECT_ROOT = "[PROJECT_ROOT]".freeze
    PROJECT_ROOT_CACHE = {}
    GEM_ROOT_CACHE = {}
    RELATIVE_ROOT = Regexp.new('^\.\/').freeze
    RAILS_ROOT = ::Rails.root.to_s.dup.freeze
    ROOT_REGEXP = Regexp.new("^#{Regexp.escape(RAILS_ROOT)}").freeze
    BACKTRACE_FILTERS = [
      lambda { |line|
        return line unless defined?(Gem)
        GEM_ROOT_CACHE[line] ||= Gem.path.reduce(line) do |line, path|
          line.sub(path, GEM_ROOT)
        end
      },
      lambda { |line|
        c = (PROJECT_ROOT_CACHE[RAILS_ROOT] ||= {})
        return c[line] if c.has_key?(line)
        c[line] ||= line.sub(ROOT_REGEXP, PROJECT_ROOT)
      },
      lambda { |line| line.sub(RELATIVE_ROOT, STRING_EMPTY) }
    ].freeze

    attr_reader :file
    attr_reader :number
    attr_reader :method
    attr_reader :filtered_file, :filtered_number, :filtered_method, :unparsed_line

    # Parses a single line of a given backtrace
    #
    # @param [String] unparsed_line The raw line from +caller+ or some backtrace.
    #
    # @return The parsed backtrace line.
    def self.parse(unparsed_line, opts = {})
      filtered_line = BACKTRACE_FILTERS.reduce(unparsed_line) do |line, proc|
        proc.call(line)
      end

      if filtered_line
        match = unparsed_line.match(INPUT_FORMAT) || [].freeze
        fmatch = filtered_line.match(INPUT_FORMAT) || [].freeze

        file, number, method = match[1], match[2], match[3]
        filtered_args = [fmatch[1], fmatch[2], fmatch[3]]
        new(unparsed_line, file, number, method, *filtered_args, opts.fetch(:source_radius, 2))
      end
    end

    def initialize(unparsed_line, file, number, method, filtered_file = file,
      filtered_number = number, filtered_method = method,
      source_radius = 2)
      self.unparsed_line = unparsed_line
      self.filtered_file = filtered_file
      self.filtered_number = filtered_number
      self.filtered_method = filtered_method
      self.file = file
      self.number = number
      self.method = method
      self.source_radius = source_radius
    end

    # Reconstructs the line in a readable fashion.
    def to_s
      "#{filtered_file}:#{filtered_number}:in `#{filtered_method}'"
    end

    def ==(other)
      to_s == other.to_s
    end

    def inspect
      "<Line:#{self}>"
    end

    # Determines if this line is part of the application trace or not.
    def application?
      (filtered_file =~ /^\[PROJECT_ROOT\]/i) && !(filtered_file =~ /^\[PROJECT_ROOT\]\/vendor/i)
    end

    def source
      @source ||= get_source(file, number, source_radius)
    end

    private

    attr_writer :file, :number, :method, :filtered_file, :filtered_number, :filtered_method, :unparsed_line

    attr_accessor :source_radius

    # Open source file and read line(s).
    #
    # Returns an array of line(s) from source file.
    def get_source(file, number, radius = 2)
      return {} unless file && File.exist?(file)

      before = after = radius
      start = (number.to_i - 1) - before
      start = 0 and before = 1 if start <= 0
      duration = before + 1 + after

      l = 0
      File.open(file) do |f|
        start.times {
          f.gets
          l += 1
        }
        return duration.times.map { (line = f.gets) ? [(l += 1), line] : nil }.compact.to_h
      end
    end
  end
end
