module SolidErrors
  class ErrorsController < ApplicationController
    before_action :set_error, only: %i[ show update ]

    # GET /errors
    def index
      @errors = Error.unresolved
                     .joins(:occurrences)
                     .select('errors.*, MAX(occurrences.created_at) AS recent_occurrence')
                     .group('errors.id')
                     .order('recent_occurrence DESC')
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
