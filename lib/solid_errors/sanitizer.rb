module SolidErrors
  # adapted from: https://github.com/honeybadger-io/honeybadger-ruby/blob/master/lib/honeybadger/util/sanitizer.rb
  class Sanitizer
    BASIC_OBJECT = "#<BasicObject>".freeze
    DEPTH = "[DEPTH]".freeze
    RAISED = "[RAISED]".freeze
    RECURSION = "[RECURSION]".freeze
    TRUNCATED = "[TRUNCATED]".freeze
    MAX_STRING_SIZE = 65536

    def self.sanitize(data)
      @sanitizer ||= new
      @sanitizer.sanitize(data)
    end

    def initialize(max_depth: 20)
      @max_depth = max_depth
    end

    def sanitize(data, depth = 0, stack = nil)
      return BASIC_OBJECT if basic_object?(data)

      if recursive?(data)
        return RECURSION if stack&.include?(data.object_id)

        stack = stack ? stack.dup : Set.new
        stack << data.object_id
      end

      case data
      when Hash
        return DEPTH if depth >= max_depth

        new_hash = {}
        data.each do |key, value|
          key = key.is_a?(Symbol) ? key : sanitize(key, depth + 1, stack)
          value = sanitize(value, depth + 1, stack)
          new_hash[key] = value
        end
        new_hash
      when Array, Set
        return DEPTH if depth >= max_depth

        data.to_a.map do |value|
          sanitize(value, depth + 1, stack)
        end
      when Numeric, TrueClass, FalseClass, NilClass
        data
      when String
        sanitize_string(data)
      else # all other objects
        klass = data.class

        begin
          data = String(data)
        rescue
          return RAISED
        end

        return "#<#{klass.name}>" if inspected?(data)

        sanitize_string(data)
      end
    end

    private

    attr_reader :max_depth

    def basic_object?(object)
      object.respond_to?(:to_s)
      false
    rescue
      # BasicObject doesn't respond to `#respond_to?`.
      true
    end

    def recursive?(data)
      data.is_a?(Hash) || data.is_a?(Array) || data.is_a?(Set)
    end

    def sanitize_string(string)
      string = string.gsub(/#<(.*?):0x.*?>/, '#<\1>') # remove object_id
      return string unless string.respond_to?(:size) && string.size > MAX_STRING_SIZE
      string[0...MAX_STRING_SIZE] + TRUNCATED
    end

    def inspected?(string)
      String(string) =~ /#<.*>/
    end
  end
end
