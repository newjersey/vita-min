require 'rails_helper'

describe MixpanelService do
  before do
    allow(Rails.env).to receive(:production?).and_return(true)
  end

  context "Testing concurrency" do
    let!(:procs) { [] }  # We maintain a list of procs because the internal the mutex prevents direct invocation
    before do
      # We don't want to bypass mixpanel, so we set a mock token
      expect(Rails.application.credentials).to receive(:dig).with(:mixpanel_token).and_return "mock-mixpanel-access-token"

      # We are not testing the tracker - so we mock bypass it.
      allow_any_instance_of(Mixpanel::Tracker).to receive(:track).and_wrap_original do |method, distinct_id, event_name, data|
        proc = method.receiver.instance_variable_get(:@sink)
        procs << Proc.new do
          proc.call(distinct_id, event_name, data)
        end
      end

      # Force the singleton to reevaluate
      MixpanelService.remove_instance_variable(:@singleton__instance__)
    end

    it 'uses a scheduled task to send buffered events to the server later' do
      expect_any_instance_of(Mixpanel::BufferedConsumer).to receive(:send!).once.with("abcde", "test_event")
      expect_any_instance_of(Mixpanel::BufferedConsumer).to receive(:flush).once

      # We will mock things so that scheduled tasks will execute immediately
      allow_any_instance_of(Concurrent::ScheduledTask).to receive(:execute).and_wrap_original do |method|
        expect(method.receiver.instance_variable_get(:@delay)).to eq 5
        proc = method.receiver.instance_variable_get(:@task)
        procs << proc
      end

      MixpanelService.instance.run(
        distinct_id: 'abcde',
        event_name: 'test_event',
        data: { test: 'OK' }
      )

      while procs.any?
        procs.pop.call
      end
    end

    it 'sends events to mixpanel once the buffer is full' do
      # For this test, we reset the buffer size from 50 to 2.
      stub_const "MixpanelService::MAX_BUFFER_SIZE", 2

      expect_any_instance_of(Mixpanel::BufferedConsumer).to receive(:send!).twice.with("abcde", "test_event")
      expect_any_instance_of(Mixpanel::BufferedConsumer).to receive(:flush).once

      # We don't actually want the scheduled task to run at all in this case - but it should be called twice
      # (It is not called that third time when the buffer is full)
      expect(MixpanelService.instance).to receive(:init_flusher).exactly(2).times

      3.times do
        MixpanelService.instance.run(
          distinct_id: 'abcde',
          event_name: 'test_event',
          data: { test: 'OK' }
        )
      end

      while procs.any?
        procs.pop.call
      end
    end

    context "in non-prod environment" do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
        allow(Rails.logger).to receive(:info)
      end

      context "development" do
        before do
          allow(Rails.env).to receive(:development?).and_return(true)
          allow(MixpanelService.instance).to receive(:init_flusher)
        end

        it 'does not send events to mixpanel even when the buffer is full' do
          # For this test, we reset the buffer size from 50 to 2.
          stub_const "MixpanelService::MAX_BUFFER_SIZE", 2

          expect_any_instance_of(Mixpanel::BufferedConsumer).not_to receive(:send!)
          expect_any_instance_of(Mixpanel::BufferedConsumer).not_to receive(:flush)

          expect(MixpanelService.instance).not_to have_received(:init_flusher)

          expect(Rails.logger).to receive(:info).with("Sending Mixpanel event: id abcde, event_name test_event, data {test: \"OK\"}")

          3.times do
            MixpanelService.instance.run(
              distinct_id: 'abcde',
              event_name: 'test_event',
              data: { test: 'OK' }
            )
          end

          expect(procs).to be_empty
        end
      end

      context "non-development" do
        before do
          allow(Rails.env).to receive(:development?).and_return(false)
          allow(MixpanelService.instance).to receive(:init_flusher)
        end

        it 'does not send events to mixpanel even when the buffer is full' do
          # For this test, we reset the buffer size from 50 to 2.
          stub_const "MixpanelService::MAX_BUFFER_SIZE", 2

          expect_any_instance_of(Mixpanel::BufferedConsumer).not_to receive(:send!)
          expect_any_instance_of(Mixpanel::BufferedConsumer).not_to receive(:flush)

          expect(MixpanelService.instance).not_to have_received(:init_flusher)

          expect(Rails.logger).not_to receive(:info)

          3.times do
            MixpanelService.instance.run(
              distinct_id: 'abcde',
              event_name: 'test_event',
              data: { test: 'OK' }
            )
          end

          expect(procs).to be_empty
        end
      end
    end
  end

  context "Testing the tracker" do
    let(:fake_consumer) { double('mixpanel buffered consumer') }
    let(:fake_tracker) { double('mixpanel tracker') }

    before do
      allow(fake_consumer).to receive(:send!)
      allow(fake_tracker).to receive(:track)
      MixpanelService.instance.instance_variable_set(:@consumer, fake_consumer)
      MixpanelService.instance.instance_variable_set(:@tracker, fake_tracker)
    end

    after do
      MixpanelService.instance.remove_instance_variable(:@consumer)
      MixpanelService.instance.remove_instance_variable(:@tracker)
    end

    context 'when called as a singleton' do
      describe '#instance' do
        it 'returns the instance' do
          expect(MixpanelService.instance).to be_a_kind_of(MixpanelService)
          expect(MixpanelService.instance).to equal(MixpanelService.instance)
        end
      end

      describe '#run' do
        let(:sent_params) do
          {
            distinct_id: 'abcde',
            event_name: 'test_event',
            data: { test: 'OK' }
          }
        end
        let(:expected_params) { ['abcde', 'test_event', { test: 'OK' }] }

        it 'calls the internal tracker with expected parameters' do
          MixpanelService.instance.run(**sent_params)
          expect(fake_tracker).to have_received(:track).with(*expected_params)
        end
      end

      describe '#data_from(obj)' do
        let(:intake) { create :intake }

        it 'behaves identically to the class version' do
          expect(MixpanelService.instance.data_from([intake]))
            .to eq(MixpanelService.data_from([intake]))
          expect(MixpanelService.instance.data_from([]))
            .to eq(MixpanelService.data_from([]))
          expect(MixpanelService.instance.data_from({ returns: 'empty' }))
            .to eq(MixpanelService.data_from({ returns: 'empty' }))
        end
      end
    end

    context 'when called as a service module' do
      let(:distinct_id) { '99991234' }
      let(:event_name) { 'test_event' }

      let(:bare_request) { ActionDispatch::Request.new({}) }

      before do
        allow(bare_request).to receive(:referrer).and_return("http://test-host.dev/remove-me/referred")
        allow(bare_request).to receive(:path).and_return("/remove-me/resource")
        allow(bare_request).to receive(:fullpath).and_return("/remove-me/resource?other_field=whatever")
      end

      describe "#strip_all_from_string" do
        it 'strips a list of strings from a target string' do
          expect(MixpanelService.strip_all_from_string('what a day', ['a', 'w']))
            .to eq('ht  dy')
        end
      end

      describe '#strip_all_from_url' do
        let(:path) { '/this/remove-me/path' }
        let(:path_plus) { '/this/remove-me/path?first=no&second=also-me' }
        let(:messy_path) { '/who/me/remove-me/path?remove=true&weird=me&dinner=meat&meet=home' }

        it 'strips a list of strings from a target url path' do
          expect(MixpanelService.strip_all_from_url(path, ['remove-me', 'immaterial']))
            .to eq('/this/***/path')
        end

        it 'strips a list of strings from a target url path and query string' do
          expect(MixpanelService.strip_all_from_url(path_plus, ['remove-me', 'also-me', 'immaterial']))
            .to eq('/this/***/path?first=no&second=***')
        end

        it 'avoids stripping subsets of urls and query strings' do
          expect(MixpanelService.strip_all_from_url(messy_path, ['me', 'meet']))
            .to eq('/who/***/remove-me/path?remove=true&weird=***&dinner=meat&***=home')
        end
      end

      describe "#send_event" do
        context "asynchronously" do
          let(:stubbed_tracker) {
            Mixpanel::Tracker.new("a_non_functional_mixpanel_key") do |type, message|
              fake_consumer.send!(type, message)
            end
          }

          before do
            MixpanelService.instance.instance_variable_set(:@tracker, stubbed_tracker)
          end

          it "sends them in a separate thread" do
            MixpanelService.send_event(distinct_id: distinct_id, event_name: event_name, data: {})
            expect(fake_consumer).to have_received(:send!).with(:event, any_args)
          end
        end

        it 'tracks an event by name and id' do
          MixpanelService.send_event(distinct_id: distinct_id, event_name: event_name, data: {})

          expect(fake_tracker).to have_received(:track).with(distinct_id, event_name, any_args)
        end

        it 'includes user agent and request information, if present' do
          MixpanelService.send_event(
            distinct_id: distinct_id,
            event_name: event_name,
            data: {},
            request: bare_request
          )

          expect(fake_tracker).to have_received(:track).with(distinct_id, event_name, hash_including(:device_browser_version))
        end

        it 'includes locale information' do
          MixpanelService.send_event(distinct_id: distinct_id, event_name: event_name, data: {})

          expect(fake_tracker).to have_received(:track).with(distinct_id, event_name, hash_including(:locale))
        end

        it 'includes submitted data:' do
          MixpanelService.send_event(distinct_id: distinct_id, event_name: event_name, data: { test: "SUCCESS" })

          expect(fake_tracker).to have_received(:track).with(distinct_id, event_name, hash_including(test: "SUCCESS"))
        end

        it 'strips intake identifiers from paths' do
          MixpanelService.send_event(
            distinct_id: distinct_id,
            event_name: event_name,
            data: {},
            request: bare_request,
            path_exclusions: ['remove-me', 'immaterial']
          )

          expect(fake_tracker).to have_received(:track).with(
            distinct_id,
            event_name,
            hash_including(
              path: "/***/resource",
              full_path: "/***/resource?other_field=whatever"
            )
          )
        end

        it 'overwrites defaults with included data' do
          MixpanelService.send_event(distinct_id: distinct_id, event_name: event_name, data: { locale: "NO!" })

          expect(fake_tracker).to have_received(:track).with(distinct_id, event_name, hash_including(locale: "NO!"))
        end
      end

      describe "#send_tax_return_event" do
        let(:coalition) { create :coalition }
        let(:organization) { create :organization, name: "Parent Org", coalition: coalition }
        let(:site) { create :site, name: "Child Site", parent_organization: organization }
        let(:client) { create :client, intake: (build :intake, visitor_id: "fake_visitor_id"), vita_partner: site }
        let(:user) { create :team_member_user, sites: [site] }

        context "when the event is triggered by a user" do
          let!(:tax_return) { create :gyr_tax_return, :intake_before_consent, certification_level: "basic", client: client, metadata: { initiated_by_user_id: user.id } }

          it "sends a Mixpanel event" do
            MixpanelService.send_tax_return_event(tax_return, "ready_for_prep", { additional_data: "1234"})

            expect(fake_tracker).to have_received(:track).with(
              "fake_visitor_id",
              "ready_for_prep",
              {
                year: tax_return.year.to_s,
                certification_level: tax_return.certification_level,
                is_ctc: false,
                service_type: tax_return.service_type,
                status: "intake_before_consent",
                client_organization_name: "Parent Org",
                client_organization_id: client.vita_partner.parent_organization.id,
                client_site_name: "Child Site",
                client_site_id: client.vita_partner.id,
                user_id: user.id,
                user_site_name: site.name,
                user_site_id: site.id,
                user_organization_name: organization.name,
                user_organization_id: organization.id,
                user_coalition_name: coalition.name,
                user_coalition_id: coalition.id,
                user_login_time: nil,
                user_role: "TeamMemberRole",
                additional_data: "1234",
              }
            )
          end
        end

        context "when the event is triggered by the system" do
          let!(:tax_return) { create :gyr_tax_return, :intake_before_consent, certification_level: "basic", client: client }

          it "handles the lack of a last_changed_by user" do
            MixpanelService.send_tax_return_event(tax_return, "ready_for_prep")

            expect(fake_tracker).to have_received(:track).with(
              "fake_visitor_id",
              "ready_for_prep",
              hash_excluding(
                {
                  user_id: user.id,
                  user_site_name: site.name,
                  user_site_id: site.id,
                  user_organization_name: organization.name,
                  user_organization_id: organization.id,
                  user_coalition_name: coalition.name,
                  user_coalition_id: coalition.id,
                  user_login_time: nil,
                  user_role: "TeamMemberRole",
                }
              )
            )
          end
        end
      end

      describe "#send_tax_return_event (status-change)" do
        let(:coalition) { create :coalition }
        let(:organization) { create :organization, name: "Parent Org", coalition: coalition }
        let(:site) { create :site, name: "Child Site", parent_organization: organization }
        let(:client) { create :client, intake: (build :intake, visitor_id: "fake_visitor_id"), vita_partner: site }
        let(:user) { create :team_member_user, sites: [site] }

        context "when the event is triggered by a user" do
          let!(:tax_return) { create :gyr_tax_return, :review_reviewing, metadata: { initiated_by_user_id: user.id }, certification_level: "basic", client: client }


          it "sends a status_change event" do
            MixpanelService.send_tax_return_event(tax_return, "status_change", { from_status: "intake_before_consent"})

            expect(fake_tracker).to have_received(:track).with(
              "fake_visitor_id",
              "status_change",
              {
                year: tax_return.year.to_s,
                certification_level: tax_return.certification_level,
                is_ctc: false,
                service_type: tax_return.service_type,
                status: "review_reviewing",
                client_organization_name: "Parent Org",
                client_organization_id: client.vita_partner.parent_organization.id,
                client_site_name: "Child Site",
                client_site_id: client.vita_partner.id,
                user_id: user.id,
                user_site_name: site.name,
                user_site_id: site.id,
                user_organization_name: organization.name,
                user_organization_id: organization.id,
                user_coalition_name: coalition.name,
                user_coalition_id: coalition.id,
                user_login_time: nil,
                user_role: "TeamMemberRole",
                from_status: "intake_before_consent"
              }
            )
          end
        end
      end

      describe "#send_file_completed_event" do
        context "event_name: filing_rejected" do
          let(:coalition) { create :coalition }
          let(:organization) { create :organization, name: "Parent Org", coalition: coalition }
          let(:site) { create :site, name: "Child Site", parent_organization: organization }
          let(:client) { create :client, intake: (build :intake, visitor_id: "fake_visitor_id"), vita_partner: site }
          let(:user) { create :team_member_user, sites: [site] }

          context "when the event is triggered by a user" do
            let(:tax_return) { create :gyr_tax_return, :prep_ready_for_prep, metadata: { initiated_by_user_id: user.id }, certification_level: "basic", client: client }

            before do
              TaxReturnTransition.where(to_state: "prep_ready_for_prep", tax_return: tax_return).update(created_at: 28.hours.ago)
              tax_return.update_column(:created_at, 2.days.ago)
            end

            it "sends a file_rejected event" do
              MixpanelService.send_file_completed_event(tax_return, "filing_rejected")

              expect(fake_tracker).to have_received(:track).with(
                  "fake_visitor_id",
                  "filing_rejected",
                  {
                      year: tax_return.year.to_s,
                      certification_level: tax_return.certification_level,
                      is_ctc: false,
                      service_type: tax_return.service_type,
                      status: tax_return.current_state,
                      client_organization_name: "Parent Org",
                      client_organization_id: client.vita_partner.parent_organization.id,
                      client_site_name: "Child Site",
                      client_site_id: client.vita_partner.id,
                      user_id: user.id,
                      user_site_name: site.name,
                      user_site_id: site.id,
                      user_organization_name: organization.name,
                      user_organization_id: organization.id,
                      user_coalition_name: coalition.name,
                      user_coalition_id: coalition.id,
                      user_login_time: nil,
                      user_role: "TeamMemberRole",
                      days_since_ready_for_prep: 1,
                      hours_since_ready_for_prep: 28,
                      days_since_tax_return_created: 2,
                      hours_since_tax_return_created: 48
                  }
              )
            end
          end

          context "when the event is triggered by the system" do
            let(:tax_return) { create :gyr_tax_return, certification_level: "basic", client: client }

            before do
              tax_return.transition_to(:prep_ready_for_prep)
              TaxReturnTransition.where(to_state: "prep_ready_for_prep", tax_return_id: tax_return.id).update(created_at: 28.hours.ago)
              tax_return.update_column(:created_at, 2.days.ago)
            end

            it "handles the lack of a last_changed_by user" do
              MixpanelService.send_file_completed_event(tax_return, "filing_rejected")

              expect(fake_tracker).to have_received(:track).with(
                  "fake_visitor_id",
                  "filing_rejected",
                  hash_excluding(
                      {
                          user_id: user.id,
                          user_site_name: site.name,
                          user_site_id: site.id,
                          user_organization_name: organization.name,
                          user_organization_id: organization.id,
                          user_coalition_name: coalition.name,
                          user_coalition_id: coalition.id,
                          user_login_time: nil,
                          user_role: "TeamMemberRole",
                      }
                  )
              )
            end
          end

          context "when ready_for_prep_at has not been set" do
            let(:tax_return) { create :gyr_tax_return, certification_level: "basic", client: client }

            before do
              tax_return.update_column(:created_at, 2.days.ago)
            end

            it "set days_since_ready_for_prep and hours_since_ready_for_prep to nil" do
              MixpanelService.send_file_completed_event(tax_return, "filing_rejected")

              expect(fake_tracker).to have_received(:track).with(
                  "fake_visitor_id",
                  "filing_rejected",
                  hash_including(
                      {
                          days_since_ready_for_prep: "N/A",
                          hours_since_ready_for_prep: "N/A",
                      }
                  )
              )
            end
          end
        end

        describe "event_name: filing_completed" do
          let(:coalition) { create :coalition }
          let(:organization) { create :organization, name: "Parent Org", coalition: coalition }
          let(:site) { create :site, name: "Child Site", parent_organization: organization }
          let(:client) { create :client, intake: (build :intake, visitor_id: "fake_visitor_id"), vita_partner: site }
          let(:user) { create :team_member_user, sites: [site] }

          context "when the event is triggered by a user" do
            let(:tax_return) { create :gyr_tax_return, :prep_ready_for_prep, certification_level: "basic", client: client, metadata: { initiated_by_user_id: user.id } }

            before do
              TaxReturnTransition.where(to_state: "prep_ready_for_prep", tax_return_id: tax_return.id).update(created_at: 28.hours.ago)
              tax_return.update_column(:created_at, 2.days.ago)
            end

            it "sends a filing_completed event" do
              MixpanelService.send_file_completed_event(tax_return, "filing_completed")

              expect(fake_tracker).to have_received(:track).with(
                  "fake_visitor_id",
                  "filing_completed",
                  {
                      year: tax_return.year.to_s,
                      certification_level: tax_return.certification_level,
                      is_ctc: false,
                      service_type: tax_return.service_type,
                      status: tax_return.current_state,
                      client_organization_name: "Parent Org",
                      client_organization_id: client.vita_partner.parent_organization.id,
                      client_site_name: "Child Site",
                      client_site_id: client.vita_partner.id,
                      user_id: user.id,
                      user_site_name: site.name,
                      user_site_id: site.id,
                      user_organization_name: organization.name,
                      user_organization_id: organization.id,
                      user_coalition_name: coalition.name,
                      user_coalition_id: coalition.id,
                      user_login_time: nil,
                      user_role: "TeamMemberRole",
                      days_since_ready_for_prep: 1,
                      hours_since_ready_for_prep: 28,
                      days_since_tax_return_created: 2,
                      hours_since_tax_return_created: 48
                  }
              )
            end
          end
        end
      end

      describe '#data_from(obj)' do
        let(:state_of_residence) { 'CA' }
        let(:primary_birth_year) { 1993 }
        let(:spouse_birth_year) { 1992 }
        let(:vita_partner) { create(:organization, name: "test_partner") }
        let(:intake) do
          create(
            :intake,
            had_disability: "no",
            spouse_had_disability: "yes",
            source: "beep",
            referrer: "http://boop.horse/mane",
            filing_joint: "no",
            had_wages: "yes",
            state_of_residence: state_of_residence,
            zip_code: "94609",
            product_year: 2023,
            needs_help_current_year: "yes",
            needs_help_previous_year_1: "no",
            needs_help_previous_year_2: "yes",
            needs_help_previous_year_3: "no",
            primary_birth_date: Date.new(primary_birth_year, 3, 12),
            spouse_birth_date: Date.new(spouse_birth_year, 5, 3),
            vita_partner: vita_partner,
            timezone: "America/Los_Angeles",
            satisfaction_face: "neutral",
            claimed_by_another: "yes",
            already_applied_for_stimulus: "no",
            with_general_navigator: true,
            with_incarcerated_navigator: false,
            with_limited_english_navigator: true,
            with_unhoused_navigator: false,
            triage_filing_status: "single",
            triage_filing_frequency: "some_years",
            triage_income_level: "12500_to_25000",
            triage_vita_income_ineligible: "no",
          )
        end


        let(:intake2) { create :intake }

        before do
          intake.dependents << create(:dependent, birth_date: Date.new(2017, 4, 21), intake: intake)
          intake.dependents << create(:dependent, birth_date: Date.new(2005, 8, 11), intake: intake)
          intake.reload
        end

        context 'when obj is an array' do
          it 'returns data for all objects in the array' do
            enumerable_data = MixpanelService.data_from([intake, intake2])
            individual_data = MixpanelService.data_from(intake).merge(MixpanelService.data_from(intake2))

            expect(enumerable_data).to eq(individual_data)
          end

          it 'returns an empty hash if the array is empty' do
            expect(MixpanelService.data_from([])).to eq({})
          end
        end

        context 'when obj is an unsupported object type' do
          it 'returns an empty hash' do
            data = MixpanelService.instance.data_from({ what: 'ever' })
            expect(data).to eq({})
          end
        end

        context 'when obj is an Intake' do
          let(:data_from_intake) { MixpanelService.data_from(intake) }

          it 'returns intake data for mixpanel' do
            data = MixpanelService.instance.data_from(intake)
            expect(data[:intake_source]).to eq(intake.source)
          end

          it "returns the expected hash" do
            expect(data_from_intake).to eq({
                                             intake_source: "beep",
                                             intake_referrer: "http://boop.horse/mane",
                                             intake_referrer_domain: "boop.horse",
                                             primary_filer_age: (MultiTenantService.new(:gyr).current_tax_year - primary_birth_year).to_s,
                                             spouse_age: (MultiTenantService.new(:gyr).current_tax_year - spouse_birth_year).to_s,
                                             with_general_navigator: true,
                                             with_incarcerated_navigator: false,
                                             with_limited_english_navigator: true,
                                             with_unhoused_navigator: false,
                                             primary_filer_disabled: "no",
                                             spouse_disabled: "yes",
                                             had_dependents: "yes",
                                             number_of_dependents: "2",
                                             had_dependents_under_6: "yes",
                                             filing_joint: "no",
                                             had_earned_income: "yes",
                                             state: intake.state_of_residence,
                                             zip_code: "94609",
                                             needs_help_current_year: "yes",
                                             needs_help_previous_year_1: "no",
                                             needs_help_previous_year_2: "yes",
                                             needs_help_previous_year_3: "no",
                                             needs_help_backtaxes: "yes",
                                             vita_partner_name: vita_partner.name,
                                             timezone: "America/Los_Angeles",
                                             csat: "neutral",
                                             claimed_by_another: "yes",
                                             already_applied_for_stimulus: "no",
                                             triage_filing_status: "single",
                                             triage_filing_frequency: "some_years",
                                             triage_income_level: "12500_to_25000",
                                             triage_vita_income_ineligible: "no",
                                           })
          end

          context "with no backtax help needed" do
            let(:intake) do
              build(
                :intake,
                needs_help_current_year: "no",
                needs_help_previous_year_1: "no",
                needs_help_previous_year_2: "no",
                needs_help_previous_year_3: "no",
              )
            end

            it "sends needs_help_backtaxes = no" do
              expect(data_from_intake).to include(needs_help_backtaxes: "no")
            end
          end
        end

        context 'when obj is a CTC Intake' do
          let(:ctc_intake) do
            create(
              :ctc_intake,
              source: "beep",
              referrer: "http://boop.horse/mane",
              primary_birth_date: Date.new(1993, 3, 12),
              spouse_birth_date: Date.new(1992, 5, 3),
              state: 'CA',
              zip_code: '94110',
              with_general_navigator: true,
              with_incarcerated_navigator: true,
              with_limited_english_navigator: false,
              with_unhoused_navigator: false
            )
          end

          let(:data_from_intake) { MixpanelService.data_from(ctc_intake) }

          it 'returns intake data for mixpanel' do
            data = MixpanelService.instance.data_from(ctc_intake)
            expect(data[:intake_source]).to eq(ctc_intake.source)
          end

          it "returns the expected hash" do
            expect(data_from_intake).to eq(
              intake_source: "beep",
              intake_referrer: "http://boop.horse/mane",
              intake_referrer_domain: "boop.horse",
              primary_filer_age: "28",
              spouse_age: "29",
              with_general_navigator: true,
              with_incarcerated_navigator: true,
              with_limited_english_navigator: false,
              with_unhoused_navigator: false,
              state: 'CA',
              zip_code: '94110'
            )
          end
        end

        context 'when obj is a Request' do
          let(:data_from_request) { MixpanelService.data_from(request) }

          context "when it is a GYR request" do
            let(:request) { ActionDispatch::Request.new("HTTP_HOST" => "test.localhost") }

            it "returns the expected hash" do
              expect(data_from_request).to include({
                                                    is_ctc: false,
                                                    domain: "test.localhost"
                                                  })
            end
          end

          context "when it is a CTC request" do
            let(:request) { ActionDispatch::Request.new("HTTP_HOST" => "ctc.test.localhost") }

            it "returns the expected hash" do
              expect(data_from_request).to include({
                                              is_ctc: true,
                                              domain: "ctc.test.localhost"
                                             })
            end
          end
        end

        context 'when obj is a TaxReturn' do
          let(:tax_return) { create :tax_return, :intake_info_requested, year: "2019", certification_level: "basic", service_type: "online_intake" }
          let(:data_from_intake) { MixpanelService.data_from(tax_return) }

          it 'returns relevant data' do
            expect(data_from_intake).to eq(
              {
                year: "2019",
                certification_level: "basic",
                service_type: "online_intake",
                status: "intake_info_requested",
                is_ctc: false
              }
            )
          end
        end

        context 'when obj is a User' do
          context "when the role is AdminRole" do
            let(:user) { create :admin_user }

            it 'returns just the user id' do
              expected = {
                user_id: user.id,
                user_site_name: nil,
                user_organization_name: nil,
                user_organization_id: nil,
                user_site_id: nil,
                user_coalition_name: nil,
                user_coalition_id: nil,
                user_login_time: nil,
                user_role: "AdminRole",
              }
              expect(MixpanelService.data_from(user)).to eq(expected)
            end
          end

          context "when the role is CoalitionLeadRole" do
            let(:user) { create :coalition_lead_user }

            it 'returns user and coalition data' do
              expected = {
                user_id: user.id,
                user_coalition_name: user.role.coalition.name,
                user_coalition_id: user.role.coalition.id,
                user_organization_name: nil,
                user_organization_id: nil,
                user_site_name: nil,
                user_site_id: nil,
                user_login_time: nil,
                user_role: "CoalitionLeadRole",
              }
              expect(MixpanelService.data_from(user)).to eq(expected)
            end
          end

          context "when the role is OrganizationLeadRole" do
            let(:coalition) { create(:coalition) }
            let(:user) { create :organization_lead_user, organization: create(:organization, coalition: coalition) }

            it 'returns user, coalition, and organization data' do
              expected = {
                user_id: user.id,
                user_coalition_name: coalition.name,
                user_coalition_id: coalition.id,
                user_organization_name: user.role.organization.name,
                user_organization_id: user.role.organization.id,
                user_site_name: nil,
                user_site_id: nil,
                user_login_time: nil,
                user_role: "OrganizationLeadRole",
              }
              expect(MixpanelService.data_from(user)).to eq(expected)
            end
          end

          context "when the role is SiteCoordinatorRole" do
            let(:coalition) { create :coalition }
            let(:organization) { create :organization, coalition: coalition }
            let(:site) { create :site, parent_organization: organization }
            let(:user) { create :site_coordinator_user, sites: [site] }

            it 'returns all user fields' do
              expected = {
                user_id: user.id,
                user_coalition_name: coalition.name,
                user_coalition_id: coalition.id,
                user_organization_name: organization.name,
                user_organization_id: organization.id,
                user_site_name: site.name,
                user_site_id: site.id,
                user_login_time: nil,
                user_role: "SiteCoordinatorRole",
              }
              expect(MixpanelService.data_from(user)).to eq(expected)
            end
          end

          context "when the role is TeamMemberRole" do
            let(:coalition) { create :coalition }
            let(:organization) { create :organization, coalition: coalition }
            let(:site) { create :site, parent_organization: organization }
            let(:user) { create :team_member_user, sites: [site] }

            it 'returns all user fields' do
              expected = {
                user_id: user.id,
                user_coalition_name: coalition.name,
                user_coalition_id: coalition.id,
                user_organization_name: organization.name,
                user_organization_id: organization.id,
                user_site_name: site.name,
                user_site_id: site.id,
                user_login_time: nil,
                user_role: "TeamMemberRole",
              }
              expect(MixpanelService.data_from(user)).to eq(expected)
            end
          end
        end

        context 'when obj is a Client' do
          context 'when client.vita_partner is an organization' do
            let(:vita_partner) { create :organization }
            let(:client) { create :client, vita_partner: vita_partner }

            it 'returns client organization data' do
              expect(MixpanelService.data_from(client)).to eq(
                {
                  client_organization_name: vita_partner.name,
                  client_organization_id: vita_partner.id,
                  client_site_name: nil,
                  client_site_id: nil,
                }
              )
            end
          end

          context 'when client.vita_partner is a site' do
            let(:organization) { create :organization }
            let(:vita_partner) { create :site, parent_organization: organization}
            let(:client) { create :client, vita_partner: vita_partner }

            it 'returns client site & organization data' do
              expect(MixpanelService.data_from(client)).to eq(
                {
                  client_organization_name: organization.name,
                  client_organization_id: organization.id,
                  client_site_name: vita_partner.name,
                  client_site_id: vita_partner.id,
                }
             )
            end
          end

          context 'when the client.vita_partner is nil' do
            let(:client) { create :client, vita_partner: nil }

            it 'returns client fields as nil' do
              expect(MixpanelService.data_from(client)).to eq(
                {
                  client_organization_name: nil,
                  client_organization_id: nil,
                  client_site_name: nil,
                  client_site_id: nil,
                }
              )
            end
          end
        end
      end
    end
  end

  ##
  # this section tests controller-specific features of mixpanel_service,
  # including the removal of identifying information in reports sent to mixpanel
  describe ApplicationController, type: :controller do
    let(:fake_tracker) { double('mixpanel tracker') }

    before do
      allow(fake_tracker).to receive(:track)
      MixpanelService.instance.instance_variable_set(:@tracker, fake_tracker)
    end

    after do
      MixpanelService.instance.remove_instance_variable(:@tracker)
    end

    controller do
      skip_after_action :track_page_view

      def index
        MixpanelService.send_event(distinct_id: '72347234', event_name: 'index_test_event', data: {}, source: self, request: request)
        render plain: 'nope'
      end

      def req_test
        request.env['HTTP_REFERER'] = "http://test.dev/9999998/rest"
        MixpanelService.send_event(distinct_id: '72347235', event_name: 'req_test_event', data: {}, request: request, path_exclusions: all_identifiers)
        render plain: 'nope'
      end

      def inst_test
        session[:intake_id] = params[:intake_id]
        MixpanelService.send_event(distinct_id: '72347236', event_name: 'inst_test_event', data: {}, request: request, path_exclusions: all_identifiers)
        render plain: 'nope'
      end
    end

    describe "#send_event" do

      it 'includes controller (source) information, if present' do
        get :index

        expect(fake_tracker).to have_received(:track).with(
          '72347234',
          'index_test_event',
          hash_including(
            :source,
            :utm_state,
            :controller_name,
            :controller_action,
            :controller_action_name
          )
        )
      end

      it 'strips :intake_id from paths' do
        routes.draw { get "req_test/:intake_id/rest" => "anonymous#req_test" }
        params = { intake_id: 9999998, secretly_also_intake_id: 9999998 }
        get :req_test, params: params

        expect(fake_tracker).to have_received(:track).with(
          '72347235',
          'req_test_event',
          hash_including(
            path: '/req_test/***/rest',
            full_path: '/req_test/***/rest?secretly_also_intake_id=***',
            referrer: 'http://test.dev/***/rest'
          )
        )
      end

      it 'strips :id from paths' do
        routes.draw { get "req_test/:id/rest" => "anonymous#req_test" }
        params = { id: 9999998, secretly_also_id: 9999998 }
        get :req_test, params: params

        expect(fake_tracker).to have_received(:track).with(
          '72347235',
          'req_test_event',
          hash_including(
            path: '/req_test/***/rest',
            full_path: '/req_test/***/rest?secretly_also_id=***',
            referrer: 'http://test.dev/***/rest'
          )
        )
      end

      it 'strips :token from paths' do
        routes.draw { get "req_test/:token/rest" => "anonymous#req_test" }
        params = { token: 9999998, secretly_also_token: 9999998 }
        get :req_test, params: params

        expect(fake_tracker).to have_received(:track).with(
          '72347235',
          'req_test_event',
          hash_including(
            path: '/req_test/***/rest',
            full_path: '/req_test/***/rest?secretly_also_token=***',
            referrer: 'http://test.dev/***/rest'
          )
        )
      end

      it 'strips :ticket_id from paths' do
        routes.draw { get "req_test/:ticket_id/rest" => "anonymous#req_test" }
        params = { ticket_id: 9999998, secretly_also_ticket_id: 9999998 }
        get :req_test, params: params

        expect(fake_tracker).to have_received(:track).with(
          '72347235',
          'req_test_event',
          hash_including(
            path: '/req_test/***/rest',
            full_path: '/req_test/***/rest?secretly_also_ticket_id=***',
            referrer: 'http://test.dev/***/rest'
          )
        )
      end

      it 'strips current_intake.id from paths' do
        intake = create(:intake)
        routes.draw { get "inst_test/:intake_id/rest" => "anonymous#inst_test" }
        get :inst_test, params: { intake_id: intake.id }

        expect(fake_tracker).to have_received(:track).with(
          '72347236',
          'inst_test_event',
          hash_including(
            path: '/inst_test/***/rest',
            full_path: '/inst_test/***/rest',
          )
        )
      end

      context "when dropping events" do
        before do
          routes.draw { get "index" => "anonymous#index" }
        end

        context "for those not allowed" do
          it "drops those from the IP address expected from SecurityMetrics" do
            @request.remote_addr = "192.211.152.30"

            get :index

            expect(fake_tracker).not_to have_received(:track)
          end

          it "drops events coming from non-public AWS domains" do
            request.set_header("HTTP_HOST", "ec2-18-204-251-64.compute-1.amazonaws.com")

            get :index

            expect(fake_tracker).not_to have_received(:track)
          end

          it "drops events coming from status checks" do
            get :index, params: { source: "hund" }

            expect(fake_tracker).not_to have_received(:track)

            get :index, params: { source: "hund.io" }

            expect(fake_tracker).not_to have_received(:track)
          end
        end

        context "for those permitted" do
          it "sends an event" do
            get :index

            expect(fake_tracker).to have_received(:track)
          end
        end
      end
    end
  end
end
