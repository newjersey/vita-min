class DirectFileData
  SELECTORS = {
    tax_return_year: 'ReturnHeader TaxYr',
    filing_status: 'IRS1040 IndividualReturnFilingStatusCd',
    primary_ssn: 'ReturnHeader Filer PrimarySSN',
    primary_occupation: 'IRS1040 PrimaryOccupationTxt',
    spouse_ssn: 'ReturnHeader Filer SpouseSSN',
    spouse_occupation: 'IRS1040 SpouseOccupationTxt',
    mailing_city: 'ReturnHeader Filer USAddress CityNm',
    mailing_street: 'ReturnHeader Filer USAddress AddressLine1Txt',
    mailing_state: 'ReturnHeader Filer USAddress StateAbbreviationCd',
    mailing_zip: 'ReturnHeader Filer USAddress ZIPCd',
    fed_tax: 'IRS1040 TotalTaxBeforeCrAndOthTaxesAmt',
    fed_agi: 'IRS1040 AdjustedGrossIncomeAmt',
    fed_wages: 'IRS1040 WagesAmt',
    fed_wages_salaries_tips: 'IRS1040 WagesSalariesAndTipsAmt',
    fed_taxable_income: 'IRS1040 TaxableInterestAmt',
    fed_unemployment: 'IRS1040Schedule1 UnemploymentCompAmt',
    fed_educator_expenses: 'IRS1040Schedule1 EducatorExpensesAmt',
    fed_student_loan_interest: 'IRS1040Schedule1 StudentLoanInterestDedAmt',
    fed_total_adjustments: 'IRS1040Schedule1 TotalAdjustmentsAmt',
    fed_taxable_ssb: 'IRS1040 TaxableSocSecAmt',
    fed_ssb: 'IRS1040 SocSecBnftAmt',
    fed_eic: 'IRS1040 EarnedIncomeCreditAmt',
  }.freeze

  def initialize(raw_xml)
    @raw_xml = raw_xml
  end

  def parsed_xml
    @parsed_xml ||= Nokogiri::XML(@raw_xml)
  end

  def to_s
    parsed_xml.to_s
  end

  def tax_return_year
    df_xml_value(__method__)&.to_i
  end

  def filing_status
    df_xml_value(__method__)&.to_i
  end

  def filing_status=(value)
    write_df_xml_value(__method__, value)
  end

  def phone_daytime
    # TODO
  end

  def phone_daytime_area_code
    # TODO
  end

  def primary_ssn
    df_xml_value(__method__)
  end

  def primary_ssn=(value)
    write_df_xml_value(__method__, value)
  end

  def primary_occupation
    df_xml_value(__method__)
  end

  def primary_occupation=(value)
    write_df_xml_value(__method__, value)
  end

  def spouse_ssn
    df_xml_value(__method__)
  end

  def spouse_ssn=(value)
    unless parsed_xml.at('Filer SpouseSSN').present? && value.present?
      parsed_xml.at('Filer').add_child('<SpouseSSN/>')
    end

    if parsed_xml.at('Filer SpouseSSN')
      parsed_xml.at('Filer SpouseSSN').content = value
    end
  end

  def spouse_occupation
    df_xml_value(__method__)
  end

  def spouse_occupation=(value)
    unless parsed_xml.at('IRS1040 SpouseOccupationTxt').present? && value.present?
      parsed_xml.at('IRS1040').add_child('<SpouseOccupationTxt/>')
    end

    if parsed_xml.at('SpouseOccupationTxt')
      parsed_xml.at('SpouseOccupationTxt').content = value
    end
  end

  def mailing_city
    df_xml_value(__method__)
  end

  def mailing_city=(value)
    write_df_xml_value(__method__, value)
  end

  def mailing_street
    df_xml_value(__method__)
  end

  def mailing_street=(value)
    write_df_xml_value(__method__, value)
  end

  def mailing_apartment
    # TODO
  end

  def mailing_state
    df_xml_value(__method__)
  end

  def mailing_state=(value)
    write_df_xml_value(__method__, value)
  end

  def mailing_zip
    parsed_xml.at('USAddress ZIPCd')&.text
  end

  def mailing_zip=(value)
    write_df_xml_value(__method__, value)
  end

  def fed_tax
    df_xml_value(__method__)&.to_i
  end

  def fed_agi
    df_xml_value(__method__)&.to_i
  end

  def fed_agi=(value)
    write_df_xml_value(__method__, value)
  end

  def fed_wages
    df_xml_value(__method__)&.to_i
  end

  def fed_wages=(value)
    write_df_xml_value(__method__, value)
  end

  def fed_wages_salaries_tips
    df_xml_value(__method__)&.to_i
  end

  def fed_taxable_income
    df_xml_value(__method__)&.to_i
  end

  def fed_taxable_income=(value)
    write_df_xml_value(__method__, value)
  end

  def fed_unemployment
    df_xml_value(__method__)&.to_i
  end

  def fed_unemployment=(value)
    write_df_xml_value(__method__, value)
  end

  def fed_taxable_ssb
    df_xml_value(__method__)&.to_i
  end

  def fed_taxable_ssb=(value)
    write_df_xml_value(__method__, value)
  end

  def fed_ssb
    df_xml_value(__method__)&.to_i
  end

  def fed_ssb=(value)
    write_df_xml_value(__method__, value)
  end

  def fed_non_taxable_ssb
    fed_ssb - fed_taxable_ssb
  end

  def fed_adjustments_claimed
    keys = [:fed_educator_expenses, :fed_student_loan_interest]
    adjustments = keys.to_h { |k| [k, df_xml_value(k)&.to_i] }
    adjustments.select { |k, v| v.present? && v > 0}
  end

  def fed_total_adjustments
    df_xml_value(__method__)&.to_i
  end

  def total_state_tax_withheld
    0 # TODO
  end

  def fed_eic_claimed
    (fed_eic || 0).positive?
  end

  def fed_eic
    df_xml_value(__method__)&.to_i
  end

  def fed_eic_qc_claimed
    parsed_xml.at('IRS1040ScheduleEIC QualifyingChildInformation') != nil
  end

  def fed_65_primary_spouse
    elements_to_check = ['Primary65OrOlderInd', 'Spouse65OrOlderInd']
    value = 0

    elements_to_check.each do |element_name|
      if parsed_xml.at(element_name)
        value += 1
      end
    end
    value
  end

  def blind_primary_spouse
    elements_to_check = ['PrimaryBlindInd', 'SpouseBlindInd']
    value = 0

    elements_to_check.each do |element_name|
      if parsed_xml.at(element_name)
        value += 1
      end
    end
    value
  end

  def ny_public_employee_retirement_contributions
    box14_total = 0
    retirement_types = ['414(H)', '414HCU', 'ERSNYSRE', 'NYSERS', 'RET', 'RETSH', 'TIER3RET', '414(H)CU', '414HSUB', 'ERSRETCO', 'NYSRETCO', 'RETDEF', 'RETSM', 'TIER4', '414H', 'ERS', 'NYRET', 'PUBRET', 'RETMT', 'TIER4RET', 'RETSUM']

    parsed_xml.css('IRSW2 OtherDeductionsBenefitsGrp').map do |deduction|
      desc = deduction.at('Desc')&.text
      amt = deduction.at('Amt')&.text.to_i

      if retirement_types.include?(desc.upcase.gsub(/\s/, ''))
        box14_total += amt
      end
    end

    box14_total
  end

  def dependents
    dependents = parsed_xml.css('DependentDetail').map do |node|
      Dependent.new(
        first_name: node.at('DependentFirstNm')&.text,
        last_name: node.at('DependentLastNm')&.text,
        ssn: node.at('DependentSSN')&.text,
        relationship: node.at('DependentRelationshipCd')&.text,
      )
    end

    parsed_xml.css('IRS1040ScheduleEIC QualifyingChildInformation').map.with_index do |node|
      dependent = dependents.map { |d| d if d.ssn == node.at('QualifyingChildSSN')&.text }.first
      next unless dependent
      if dependent.present?
        dependent.eic_qualifying = true
        dependent.eic_student = node.at('ChildIsAStudentUnder24Ind')&.text
        dependent.eic_disability = node.at('ChildPermanentlyDisabledInd')&.text
        dependent.months_in_home = node.at('MonthsChildLivedWithYouCnt')&.text
      else
        dependents << Dependent.new(
          first_name: node.at('ChildFirstAndLastName PersonFirstNm')&.text,
          last_name: node.at('ChildFirstAndLastName PersonLastNm')&.text,
          ssn: node.at('QualifyingChildSSN')&.text,
          relationship: node.at('ChildRelationshipCd')&.text,
          eic_qualifying: true,
          eic_student: node.at('ChildIsAStudentUnder24Ind')&.text,
          eic_disability: node.at('ChildPermanentlyDisabledInd')&.text,
          months_in_home: node.at('MonthsChildLivedWithYouCnt')&.text,
          )
      end
    end
    dependents
  end

  class Dependent
    attr_accessor :first_name,
                  :last_name,
                  :ssn,
                  :relationship,
                  :eic_student,
                  :eic_disability,
                  :months_in_home,
                  :eic_qualifying

    def initialize(first_name:, last_name:, ssn:, relationship:,
                   eic_student: nil, eic_disability: nil, months_in_home: nil, eic_qualifying: nil)

      @first_name = first_name
      @last_name = last_name
      @ssn = ssn
      @relationship = relationship
      @eic_student = eic_student
      @eic_disability = eic_disability
      @months_in_home = months_in_home
      @eic_qualifying = eic_qualifying
    end

    def attributes
      {
        first_name: @first_name,
        last_name: @last_name,
        ssn: @ssn,
        relationship: @relationship,
        eic_student: @eic_student,
        eic_disability: @eic_disability,
        months_in_home: @months_in_home,
        eic_qualifying: @eic_qualifying,
      }
    end
  end

  def attributes
    [
      :tax_return_year,
      :filing_status,
      :phone_daytime,
      :phone_daytime_area_code,
      :primary_ssn,
      :primary_occupation,
      :spouse_ssn,
      :spouse_occupation,
      :mailing_city,
      :mailing_street,
      :mailing_apartment,
      :mailing_zip,
      :fed_wages,
      :fed_taxable_income,
      :fed_unemployment,
      :fed_taxable_ssb,
      :fed_adjustments_claimed,
      :fed_total_adjustments,
      :total_state_tax_withheld
    ].each_with_object({}) do |field, hsh|
      hsh[field] = send(field)
    end
  end

  def can_override?(attribute)
    return false if Rails.env.production?

    respond_to?("#{attribute}=")
  end

  private

  def df_xml_value(key)
    parsed_xml.at(SELECTORS[key])&.text
  end

  def write_df_xml_value(key, value)
    # Remove trailing equals sign from method e.g. :filing_status= -> :filing_status
    selector = SELECTORS[key.to_s.sub(/=$/, '').to_sym]
    parsed_xml.at(selector).content = value
  end
end