module SolidErrors
  class Occurrence < Record
    belongs_to :error, class_name: "SolidErrors::Error"

    # Adapters that report the json column as text (MariaDB) would otherwise store Hash#inspect
    attribute :context, :json

    # :created or :reopened, set by the subscriber when this occurrence opens its error
    attr_accessor :opens_error

    after_create_commit :send_email, if: -> { SolidErrors.send_emails? && (SolidErrors.email_every_occurrence || opens_error) }
    after_create_commit :publish_events
    after_create_commit :clear_resolved_errors, if: :should_clear_resolved_errors?

    # The parsed exception backtrace. Lines in this backtrace that are from installed gems
    # have the base path for gem installs replaced by "[GEM_ROOT]", while those in the project
    # have "[PROJECT_ROOT]".
    # @return [Array<{:number, :file, :method => String}>]
    def parsed_backtrace
      return @parsed_backtrace if defined? @parsed_backtrace

      @parsed_backtrace = parse_backtrace(backtrace&.split("\n"))
    end

    private

    def parse_backtrace(backtrace)
      Backtrace.parse(backtrace)
    end

    def publish_events
      payload = {error: error, occurrence: self}
      ActiveSupport::Notifications.instrument("error_#{opens_error}.solid_errors", payload) if opens_error
      ActiveSupport::Notifications.instrument("occurrence_created.solid_errors", payload)
    end

    def send_email
      # Passed along rather than read off the occurrence, which the mailer job loads afresh without it
      ErrorMailer.error_occurred(self, opens_error).deliver_later
    end

    def clear_resolved_errors
      transaction do
        SolidErrors::Occurrence
          .where(error: SolidErrors::Error.resolved)
          .where(created_at: ...SolidErrors.destroy_after.ago)
          .delete_all
        SolidErrors::Error.resolved
          .where
          .missing(:occurrences)
          .delete_all
      end
    end

    def should_clear_resolved_errors?
      return false unless SolidErrors.destroy_after
      return false unless SolidErrors.destroy_after.respond_to?(:ago)
      return false unless (id % 100).zero?

      true
    end
  end
end
