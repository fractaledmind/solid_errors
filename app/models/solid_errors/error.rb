module SolidErrors
  class Error < Record
    self.table_name = "solid_errors"

    SEVERITY_TO_EMOJI = {
      error: "🔥",
      warning: "⚠️",
      info: "ℹ️"
    }
    SEVERITY_TO_BADGE_CLASSES = {
      error: "bg-red-100 text-red-800",
      warning: "bg-yellow-100 text-yellow-800",
      info: "bg-blue-100 text-blue-800"
    }
    STATUS_TO_EMOJI = {
      resolved: "✅",
      unresolved: "⏳"
    }
    STATUS_TO_BADGE_CLASSES = {
      resolved: "bg-green-100 text-green-800",
      unresolved: "bg-violet-100 text-violet-800"
    }

    has_many :occurrences, class_name: "SolidErrors::Occurrence", dependent: :destroy

    validates :exception_class, presence: true
    validates :message, presence: true
    validates :severity, presence: true

    scope :resolved, -> { where.not(resolved_at: nil) }
    scope :unresolved, -> { where(resolved_at: nil) }

    after_update_commit :publish_resolved, if: -> { saved_change_to_resolved_at? && resolved? }

    def severity_emoji
      SEVERITY_TO_EMOJI[severity.to_sym]
    end

    def severity_badge_classes
      "px-2 inline-flex text-sm font-semibold rounded-md #{SEVERITY_TO_BADGE_CLASSES[severity.to_sym]}"
    end

    def status
      resolved? ? :resolved : :unresolved
    end

    def status_emoji
      STATUS_TO_EMOJI[status]
    end

    def status_badge_classes
      "px-2 inline-flex text-sm font-semibold rounded-md #{STATUS_TO_BADGE_CLASSES[status]}"
    end

    def resolved?
      resolved_at.present?
    end

    def to_markdown
      md = ""
      md << "## Exception: #{exception_class}\n"
      md << "**Severity:** #{severity} | **Source:** #{source}\n\n"
      md << "### Message\n#{message}\n"

      occurrence = occurrences.order(created_at: :desc).first
      return md unless occurrence

      backtrace = occurrence.parsed_backtrace

      md << "\n### Backtrace\n"
      backtrace.lines.each do |line|
        md << (line.filtered_method ? line.to_s : line.unparsed_line) << "\n"
      end

      app_lines = backtrace.application_lines
      if app_lines.any?
        md << "\n### Source Context\n"
        app_lines.each do |line|
          md << "#### #{line}\n"
          md << "```ruby\n"
          line.source.each { |n, code| md << "#{n}: #{code.chomp}\n" }
          md << "```\n\n"
        end
      end

      if occurrence.context.present?
        md << "### Request Context\n"
        occurrence.context.each { |k, v| md << "- #{k}: #{v}\n" }
      end

      md
    end

    private

    def publish_resolved
      ActiveSupport::Notifications.instrument("error_resolved.solid_errors", error: self)
    end
  end
end
