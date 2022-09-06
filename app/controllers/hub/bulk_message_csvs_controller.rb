module Hub
  class BulkMessageCsvsController < ApplicationController
    include AccessControllable
    before_action :require_sign_in
    load_and_authorize_resource

    layout "hub"

    def index
      @main_heading = "Bulk messaging CSVs"
      @bulk_message_csv = BulkMessageCsv.new
    end

    def create
      if @bulk_message_csv.valid?
        @bulk_message_csv.save
        BulkAction::MessageCsvImportJob.perform_later(@bulk_message_csv)
        redirect_to action: :index
      else
        @bulk_message_csvs = BulkMessageCsv.all
        render :index
      end
    end

    private

    def create_params
      params.require(:bulk_message_csv).permit(:upload).merge(user: current_user, status: :queued)
    end
  end
end
