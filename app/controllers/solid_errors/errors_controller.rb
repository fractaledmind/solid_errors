module SolidErrors
  class ErrorsController < ApplicationController
    before_action :set_error, only: %i[ show update ]

    # GET /errors
    def index
      errors_table = Error.arel_table
      occurrences_table = Occurrence.arel_table
      recent_occurrence = occurrences_table
        .project(occurrences_table[:created_at].maximum)
        .as('recent_occurrence')

      @errors = Error.unresolved
                     .joins(:occurrences)
                     .select(errors_table[Arel.star], recent_occurrence)
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
  end
end
