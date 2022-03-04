class PublicPagesController < ApplicationController
  skip_before_action :check_maintenance_mode
  skip_after_action :track_page_view, only: [:healthcheck]

  def include_analytics?
    true
  end

  def redirect_locale_home
    redirect_to root_path
  end

  def source_routing
    vita_partner = SourceParameter.find_vita_partner_by_code(params[:source])
    if vita_partner.present?
      flash[:notice] = I18n.t("controllers.public_pages.partner_welcome_notice", partner_name: vita_partner.name)
      cookies[:used_unique_link] = {value: "yes", expiration: 1.year.from_now.utc }
    end
    redirect_to root_path
  end

  def home; end

  def pending; end

  def healthcheck
    render :home
  end

  def other_options; end

  def maybe_ineligible; end

  def privacy_policy; end

  def about_us; end

  def maintenance; end

  def internal_server_error
    respond_to do |format|
      format.html { render 'public_pages/internal_server_error', status: 500  }
      format.any { head 500 }
    end
  end

  def page_not_found
    respond_to do |format|
      format.html { render 'public_pages/page_not_found', status: 404  }
      format.any { head 404 }
    end
  end

  def tax_questions; end

  def stimulus
    # the copy on this page is wrong and until we get it updated, redirect to beginning of intake
    redirect_to_beginning_of_intake
  end

  def full_service
    session[:source] = "full-service"
    redirect_to_intake_after_triage
  end

  def stimulus_recommendation; end

  def sms_terms; end

  def diy
    redirect_to root_path unless open_for_intake?
  end

  def pki_validation
    # Used for Identrust annual EV certificate validation
    respond_to do |format|
      format.text { render 'public_pages/pki_validation'  }
      format.any { head 404 }
    end
  end
end
