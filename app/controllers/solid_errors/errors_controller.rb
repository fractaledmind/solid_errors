module SolidErrors
  class ErrorsController < ApplicationController
    around_action :force_english_locale!

    before_action :set_error, only: %i[show update]

    # GET /errors
    def index
      errors_table = Error.arel_table
      occurrences_table = Occurrence.arel_table

      @errors = Error.unresolved
        .joins(:occurrences)
        .select(errors_table[Arel.star],
          occurrences_table[:created_at].maximum.as("recent_occurrence"),
          occurrences_table[:id].count.as("occurrences_count"))
        .group(errors_table[:id])
        .order(recent_occurrence: :desc)
    end

    # GET /errors/1
    def show
    end

    # PATCH/PUT /errors/1
    def update
      @error.update!(error_params)
      redirect_to errors_path, notice: "Error marked as resolved."
    end

    private

    # Only allow a list of trusted parameters through.
    def error_params
      params.require(:error).permit(:resolved_at)
    end

    def set_error
      @error = Error.find(params[:id])
    end

    def force_english_locale!(&action)
      I18n.with_locale(:en, &action)
    end
  end
end
