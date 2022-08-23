module Efile
  class BenefitsEligibility
    attr_accessor :year, :eligible_filer_count, :dependents, :intake, :tax_return
    def initialize(tax_return:, dependents:)
      @tax_return = tax_return
      @year = tax_return.year
      @intake = tax_return.intake
      @dependents = dependents
      @eligible_filer_count = rrc_eligible_filer_count
    end

    def eip1_amount
      return 0 unless year == 2020

      sum = 1200 * eligible_filer_count
      sum += dependents.map { |d| Efile::DependentEligibility::EipOne.new(d, year).benefit_amount }.sum
      sum
    end

    def outstanding_eip1
      [eip1_amount - intake.eip1_amount_received, 0].max
    end

    def eip2_amount
      return 0 unless year == 2020

      sum = 600 * eligible_filer_count
      sum += dependents.map { |d| Efile::DependentEligibility::EipTwo.new(d, year).benefit_amount }.sum
      sum
    end

    def outstanding_eip2
      [eip2_amount - intake.eip2_amount_received, 0].max
    end

    def eip3_amount
      sum = 1400 * eligible_filer_count
      sum += dependents.map { |d| Efile::DependentEligibility::EipThree.new(d, year).benefit_amount }.sum
      sum
    end

    def eip3_amount_received
      intake.eip3_amount_received || 0
    end

    def outstanding_eip3
      [eip3_amount - eip3_amount_received, 0].max
    end

    def ctc_amount
      return 0 if year == 2020

      dependents.map { |d| Efile::DependentEligibility::ChildTaxCredit.new(d, year).benefit_amount }.sum
    end

    def outstanding_ctc_amount
      [ctc_amount - advance_ctc_amount_received, 0].max
    end

    def advance_ctc_amount_received
      intake.advance_ctc_amount_received || 0
    end

    # A quick calculation for ODC (Other Dependents Credit) which does not get paid out to our filers,
    # but is needed for the 8812 calculation.
    def odc_amount
      return nil if intake.home_location_puerto_rico?
      return 0 if year == 2020

      dependents.count { |d| !d.qualifying_ctc? && (d.qualifying_child? || d.qualifying_relative?) } * 500
    end

    def outstanding_recovery_rebate_credit
      if year == 2020
        return nil unless intake.eip1_amount_received && intake.eip2_amount_received

        outstanding_eip1 + outstanding_eip2
      elsif year == 2021
        return nil unless intake.eip3_amount_received

        outstanding_eip3
      end
    end

    def claimed_recovery_rebate_credit
      return nil if intake.home_location_puerto_rico?
      return 0 if intake.claim_owed_stimulus_money_no?

      outstanding_recovery_rebate_credit
    end

    def claiming_and_qualified_for_eitc?
      intake.claim_eitc_yes? && qualified_for_eitc?
    end

    def qualified_for_eitc?
      intake.exceeded_investment_income_limit_no? && eitc_qualifications_passes_age_test? && eitc_qualifications_valid_ssns?
    end

    private

    def eitc_qualifications_passes_age_test?
      return true if age_at_end_of_tax_year >= 24
      return true if dependents.any?(&:qualifying_eitc?)

      if intake.former_foster_youth_yes? || intake.homeless_youth_yes?
        age_at_end_of_tax_year >= 18
      elsif intake.not_full_time_student_yes? || intake.full_time_student_less_than_four_months_yes?
        age_at_end_of_tax_year >= 19
      else
        false
      end
    end

    def eitc_qualifications_valid_ssns?
      return false if intake.primary_tin_type != "ssn"

      intake.dependents.none? || intake.dependents.pluck(:tin_type).include?("ssn")
    end

    def age_at_end_of_tax_year
      tax_return.year - intake.primary_birth_date.year
    end

    def rrc_eligible_filer_count
      case tax_return.filing_status
      when "single", "head_of_household"
        intake.primary_tin_type == "ssn" ? 1 : 0
      when "married_filing_jointly"
        # if one spouse is a member of the armed forces, both qualify for benefits
        return 2 if [intake.primary_active_armed_forces, intake.spouse_active_armed_forces].any?("yes")

        # only filers with SSNs (valid for employment) are eligible for RRC
        [intake.primary_tin_type, intake.spouse_tin_type].count { |tin_type| tin_type == "ssn" }
      else
        raise "unsupported filing type"
      end
    end
  end
end