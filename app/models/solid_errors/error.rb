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

    has_many :occurrences, class_name: "SolidErrors::Occurrence", dependent: :destroy

    validates :exception_class, presence: true
    validates :message, presence: true
    validates :severity, presence: true

    scope :resolved, -> { where.not(resolved_at: nil) }
    scope :unresolved, -> { where(resolved_at: nil) }

    def emoji
      SEVERITY_TO_EMOJI[severity.to_sym]
    end

    def badge_classes
      "px-2 inline-flex text-sm font-semibold rounded-md #{SEVERITY_TO_BADGE_CLASSES[severity.to_sym]}"
    end

    def resolved?
      resolved_at.present?
    end
  end
end
