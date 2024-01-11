module PdfFiller
  class Az140Pdf
    include PdfHelper

    def source_pdf_name
      "az140-TY2023"
    end

    def initialize(submission)
      @submission = submission

      # Most PDF fields are grabbed right off the XML
      @xml_document = SubmissionBuilder::Ty2022::States::Az::IndividualReturn.new(submission).document
    end

    def hash_for_pdf
      answers = {
        # TODO: name information doesn't seem to exist in AZ schema, just NameControl
        "1a" => [@xml_document.at('Primary TaxpayerName FirstName')&.text, @xml_document.at('Primary TaxpayerName MiddleInitial')&.text].join(' '),
        "1b" => @xml_document.at('Primary TaxpayerName LastName')&.text,
        "1c" => @xml_document.at('Primary TaxpayerSSN')&.text,
        "1d" => [@xml_document.at('Secondary TaxpayerName FirstName')&.text, @xml_document.at('Secondary TaxpayerName MiddleInitial')&.text].join(' '),
        "1e" => @xml_document.at('Secondary TaxpayerName LastName')&.text,
        "1f" => @xml_document.at('Secondary TaxpayerSSN')&.text,
        "2a" => @xml_document.at("USAddress AddressLine1Txt")&.text,
        "2c" => @xml_document.at("USPhone")&.text,
        "City, Town, Post Office" => @xml_document.at("CityNm")&.text,
        "State" => @xml_document.at("StateAbbreviationCd")&.text,
        "ZIP Code" => @xml_document.at("ZIPCd")&.text,
        "Filing Status" => filing_status,
        "Last Names 4 years" => @xml_document.at('LNPriorYrs')&.text,
        "8" => @xml_document.at("AgeExemp")&.text,
        "9" => @xml_document.at("VisionExemp")&.text,
        "10a" => @xml_document.at("DependentsUnder17")&.text,
        "10b" => @xml_document.at("Dependents17AndOlder")&.text,
        "11a" => @xml_document.at("QualifyingParentsAncestors")&.text,
      }

      if @xml_document.css('DependentsDetail').length > 14
        # TODO: 14 is the 3 on page 1 plus the 11 extra rows on page 4. Seems exceedingly unlikely anyone will exceed this.
        raise "Can't handle this many dependents for Form 140!"
      end

      answers["10a_10b check box"] = 'Yes' if @xml_document.css('DependentsDetail').length > 3
      @submission.data_source.dependents.reject(&:is_qualifying_parent_or_grandparent?).each_with_index do |dependent, index|
        # PDF fields seem to be named consistently (10c ... 10p) whether they are on Page 1 or Page 4
        prefix = "10#{('c'..'p').to_a[index]}"
        answers.merge!(
          "#{prefix} First" => dependent.first_name,
          "#{prefix} Last" => dependent.last_name,
          "#{prefix} SSN" => dependent.ssn.delete('-'),
          "#{prefix} Relationship" => dependent.relationship_label,
          "#{prefix} Mo in Home" => dependent.months_in_home,
          "#{prefix}_10a check box" => dependent.under_17? ? "X" : nil,
          "#{prefix}_10b check box" => dependent.under_17? ? nil : "X",
        )
      end

      if @xml_document.css('QualParentsAncestors').length > 8
        # TODO: 8 is the 2 on page 1 plus the 6 extra rows on page 4. Seems exceedingly unlikely anyone will exceed this.
        raise "Can't handle this many dependents for Form 140!"
      end

      answers["11a check box"] = 'Yes' if @xml_document.css('QualParentsAncestors').length > 2

      @submission.data_source.dependents.select(&:is_qualifying_parent_or_grandparent?).each_with_index do |dependent, index|
        # PDF fields seem to be named consistently (11b ... 11i) whether they are on Page 1 or Page 4
        prefix = "11#{('b'..'i').to_a[index]}"
        answers.merge!(
          "#{prefix} First" => dependent.first_name,
          "#{prefix} Last" => dependent.last_name,
          "#{prefix} SSN" => dependent.ssn.delete('-'),
          "#{prefix} Relationship" => dependent.relationship_label,
          "#{prefix} Mo in Home" => dependent.months_in_home,
          "#{prefix} over 65" => "X", # all of these dependents are 65 or older
          "#{prefix} died" => dependent.passed_away_yes? ? "X" : nil,
        )
      end

      answers.merge!({
        "19" => @xml_document.at('AzAdjSubtotal')&.text,
        "12" => @xml_document.at('FedAdjGrossIncome')&.text,
        "14" => @xml_document.at('ModFedAdjGrossInc')&.text,
        "30" => @xml_document.at('USSSRailRoadBnft')&.text,
        "31" => @xml_document.at('WageAmIndian')&.text,
        "32" => @xml_document.at('CompNtnlGrdArmdFrcs')&.text,
        "35" => @xml_document.at('TotalSubtractions')&.text,
        "37" => @xml_document.at('Form140/Subtotal')&.text,
        "42" => @xml_document.at('AZAdjGrossIncome')&.text,
        "Itemized/Standard" => 'Choice2',
        "43" => @xml_document.at('AZDeductions')&.text,
        "44" => @xml_document.at('TotalIncStdDeduction')&.text,
        "44C" => charitable_contributions,
        "45" => @xml_document.at('AZTaxableInc')&.text,
        "46" => @xml_document.at('ComputedTax')&.text,
        "48" => @xml_document.at('Form140/DeductionAmt/SubTotal')&.text,
        "49" => @xml_document.at('DepTaxCredit')&.text,
        "50" => @xml_document.at('FamilyIncomeTaxCredit')&.text,
        "52" => @xml_document.at('BalanceOfTaxDue')&.text,
        "53" => @xml_document.at('AzIncTaxWithheld')&.text,
        "56" => @xml_document.at('IncrExciseTaxCr')&.text,
        "59" => @xml_document.at('TotalPayments')&.text,
        "60" => @xml_document.at('TaxDue')&.text,
        "61" => @xml_document.at('OverPaymentOfTax')&.text,
        "63" => @xml_document.at('OverPaymentBalance')&.text,
        "79" => @xml_document.at('RefundAmt')&.text,
        "80" => @xml_document.at('AmtOwed')&.text,
        "3_1c" => @xml_document.at('GiftByCashOrCheck')&.text,
        "3_2c" => @xml_document.at('OtherThanCashOrCheck')&.text,
        "3_3c" => @xml_document.at('CarrPriorYear')&.text,
        "3_4c" => @xml_document.at('SubTotalContributions')&.text,
        "3_5c" => @xml_document.at('TotalContributions')&.text,
        "3_6c" => @xml_document.at('SubTotal')&.text,
        "3_7c" => @xml_document.at('TotalIncStdDeduction')&.text,
      })
      answers
    end

    private

    def calculated_fields
      @calculated_fields ||= @submission.data_source.tax_calculator.calculate
    end
    
    FILING_STATUS_OPTIONS = {
      "MarriedJoint" => 'Choice1',
      "HeadHousehold" => 'Choice2',
      "MarriedFilingSeparateReturn" => 'Choice3',
      "Single" => 'Choice4',
    }

    def filing_status
      FILING_STATUS_OPTIONS[@xml_document.at('FilingStatus')&.text]
    end

    def charitable_contributions
      if @xml_document.at('CharitableDeduction')&.text == 'X'
        'Yes'
      else
        "Off"
      end
    end
  end
end
