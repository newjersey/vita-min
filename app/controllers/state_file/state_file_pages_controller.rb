module StateFile
  class StateFilePagesController < ApplicationController
    layout "state_file"

    def redirect_locale_home
      redirect_to root_path
    end

    def home
    end

    def clear_session
      session.delete(:state_file_intake)
      redirect_to action: :home
    end
  end
end
