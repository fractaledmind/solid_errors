module SolidErrors
  class ErrorsController < ApplicationController
    around_action :force_english_locale!

    before_action :set_error, only: %i[show update destroy]

    helper_method :error_scope

    # GET /errors
    def index
      errors_table = Error.arel_table
      occurrences_table = Occurrence.arel_table
      query_scope = error_scope.resolved? ? Error.resolved : Error.unresolved
      @errors = query_scope
        .joins(:occurrences)
        .select(errors_table[Arel.star],
          occurrences_table[:created_at].maximum.as("recent_occurrence"),
          occurrences_table[:id].count.as("occurrences_count"))
        .group(errors_table[:id])
        .order(recent_occurrence: :desc)
    end

    # GET /errors/1
    def show
      @page = Page.new(@error.occurrences, params)
      @occurrences = @error.occurrences.offset(@page.offset).limit(@page.items).order(created_at: :desc)
    end

    # PATCH/PUT /errors/1
    def update
      @error.update!(error_params)
      redirect_to errors_path, notice: "Error marked as resolved."
    end

    # DELETE /errors/1
    def destroy
      if @error.resolved?
        @error.destroy
        redirect_to errors_path(scope: :resolved), notice: "Error deleted."
      else
        redirect_to error_path(@error), alert: "You must resolve the error before deleting it."
      end
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

    def error_scope
      ActiveSupport::StringInquirer.new(params[:scope] || "unresolved")
    end
  end
end
