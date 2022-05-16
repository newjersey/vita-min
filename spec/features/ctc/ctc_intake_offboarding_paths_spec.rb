require "rails_helper"

RSpec.feature "CTC Intake", :flow_explorer_screenshot_i18n_friendly, active_job: true, requires_default_vita_partners: true do
  before do
    allow_any_instance_of(Routes::CtcDomain).to receive(:matches?).and_return(true)
  end

  context "offboarding duplicate clients" do
    before do
      # create duplicated intake
      create(:ctc_intake,
             primary_consented_to_service_at: DateTime.now,
             primary_ssn: "111-22-8888",
             email_address: "mango@example.com",
             email_notification_opt_in: "yes",
             email_address_verified_at: DateTime.now
           )
    end

    scenario "new client entering ctc intake flow" do
      # =========== BASIC INFO ===========
      visit "/en/questions/overview"
      expect(page).to have_selector(".toolbar", text: "GetCTC") # Check for appropriate header
      expect(page).to have_selector("h1", text: I18n.t('views.ctc.questions.overview.title'))
      click_on I18n.t('general.continue')

      expect(page).to have_selector("h1", text: I18n.t('views.ctc.questions.filing_status.title'))
      choose I18n.t('general.filing_status.single')
      click_on I18n.t('general.continue')

      expect(page).to have_selector(".toolbar", text: "GetCTC")
      within "h1" do
        expect(page.source).to include(I18n.t('views.ctc.questions.income.title.one', current_tax_year: current_tax_year))
      end
      click_on I18n.t('general.continue')
      click_on I18n.t("views.ctc.questions.file_full_return.simplified_btn")
      expect(page).to have_selector("h1", text: I18n.t('views.ctc.questions.restrictions.title'))
      click_on I18n.t('general.continue')

      # =========== ELIGIBILITY ===========
      expect(page).to have_selector("h1", text: I18n.t('views.ctc.questions.already_filed.title', current_tax_year: current_tax_year))
      click_on I18n.t('general.negative')
      expect(page).to have_selector("h1", text: I18n.t('views.ctc.questions.home.title', current_tax_year: current_tax_year))
      choose I18n.t('views.ctc.questions.home.options.foreign_address')
      click_on I18n.t('general.continue')
      expect(page).to have_selector("h1", text:  I18n.t('views.ctc.questions.use_gyr.title'))
      click_on I18n.t('general.back')
      expect(page).to have_selector("h1", text: I18n.t('views.ctc.questions.home.title', current_tax_year: current_tax_year))
      choose I18n.t('views.ctc.questions.home.options.fifty_states')
      click_on I18n.t('general.continue')
      expect(page).to have_selector("h1", text: I18n.t('views.ctc.questions.life_situations.title', current_tax_year: current_tax_year))
      click_on I18n.t('general.negative')

      # =========== BASIC INFO ===========
      expect(page).to have_selector("h1", text: I18n.t('views.ctc.questions.legal_consent.title'))
      fill_in I18n.t('views.ctc.questions.legal_consent.first_name'), with: "Gary"
      fill_in I18n.t('views.ctc.questions.legal_consent.middle_initial'), with: "H"
      fill_in I18n.t('views.ctc.questions.legal_consent.last_name'), with: "Mango"
      fill_in "ctc_legal_consent_form_primary_birth_date_month", with: "08"
      fill_in "ctc_legal_consent_form_primary_birth_date_day", with: "24"
      fill_in "ctc_legal_consent_form_primary_birth_date_year", with: "1996"
      fill_in I18n.t('views.ctc.questions.legal_consent.ssn'), with: "111-22-8888"
      fill_in I18n.t('views.ctc.questions.legal_consent.ssn_confirmation'), with: "111-22-8888"
      fill_in I18n.t('views.ctc.questions.legal_consent.sms_phone_number'), with: "831-234-5678"
      check "agree_to_privacy_policy"
      click_on I18n.t('general.continue')

      expect(page).to have_selector("h1", text: I18n.t("views.questions.returning_client.title"))

      within "main" do
        click_on I18n.t("general.sign_in")
      end

      expect(page).to have_selector("h1", text: I18n.t("portal.client_logins.new.title"))
    end
  end

  context "offboarding Puerto Rico clients" do
    scenario "client can return home or sign up" do
      # =========== BASIC INFO ===========
      visit "/en/questions/overview"
      expect(page).to have_selector(".toolbar", text: "GetCTC") # Check for appropriate header
      expect(page).to have_selector("h1", text: I18n.t('views.ctc.questions.overview.title'))
      click_on I18n.t('general.continue')

      expect(page).to have_selector("h1", text: I18n.t('views.ctc.questions.filing_status.title'))
      choose I18n.t('general.filing_status.single')
      click_on I18n.t('general.continue')

      expect(page).to have_selector(".toolbar", text: "GetCTC")
      within "h1" do
        expect(page.source).to include(I18n.t('views.ctc.questions.income.title.one', current_tax_year: current_tax_year))
      end
      click_on I18n.t('general.continue')
      click_on I18n.t("views.ctc.questions.file_full_return.simplified_btn")
      expect(page).to have_selector("h1", text: I18n.t('views.ctc.questions.restrictions.title'))
      click_on I18n.t('general.continue')

      # =========== ELIGIBILITY ===========
      expect(page).to have_selector("h1", text: I18n.t('views.ctc.questions.already_filed.title', current_tax_year: current_tax_year))
      click_on I18n.t('general.negative')
      expect(page).to have_selector("h1", text: I18n.t('views.ctc.questions.home.title', current_tax_year: current_tax_year))
      choose "Puerto Rico"
      click_on I18n.t('general.continue')
      expect(page).to have_selector("h1", text: "We aren’t currently accepting returns from Puerto Rico, but you can sign up to be notified when we do.")
      expect(page).to have_link(href: ctc_root_path)
      click_on "Continue to sign up page"
      expect(page).to have_current_path(ctc_signups_path)
    end
  end
end