module SolidErrors
  class Cleaner
    class << self
      def go!
        destroy_records if destroy_after_last_create?
      end

      private

      def destroy_after_last_create?
        SolidErrors.destroy_after.respond_to?(:ago) && (SolidErrors::Occurrence.last.id % 100).zero?
      end

      def destroy_records
        ActiveRecord::Base.transaction do
          destroy_occurrences
          destroy_errors
        end
      end

      def destroy_occurrences
        SolidErrors::Occurrence.joins(:error)
                                .merge(SolidErrors::Error.resolved)
                                .where(created_at: ...SolidErrors.destroy_after.ago)
                                .delete_all
      end

      def destroy_errors
        SolidErrors::Error.resolved
                          .where
                          .missing(:occurrences)
                          .delete_all
      end
    end
  end
end
