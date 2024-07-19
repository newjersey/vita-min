module SubmissionBuilder
  module Ty2022
    module States
      module Nj
        module Documents
          class Nj1040 < SubmissionBuilder::Document
            include SubmissionBuilder::FormattingMethods

            FILING_STATUS_ELEMENT = {
              :married_filing_jointly => 'MarriedCuPartFilingJoint',
              :head_of_household => 'HeadOfHousehold',
              :married_filing_separately => 'MarriedCuPartFilingSeparate',
              :single => "Single",
              :qualifying_widow => "QualWidOrWider"
            }.freeze

            def document
              qualifying_dependents = @submission.qualifying_dependents
              
              build_xml_doc("FormNJ1040") do |xml|
                xml.Header do
                  xml.FilingStatus do
                    status = intake.filing_status.to_sym
                    case status
                    when :married_filing_separately
                      xml.MarriedCuPartFilingSeparate do
                        xml.SpouseSSN intake.spouse_ssn
                        xml.SpouseName do
                          xml.FirstName intake.spouse_first_name
                          xml.MiddleInitial intake.spouse_middle_initial if intake.spouse_middle_initial.present?
                          xml.LastName intake.spouse_last_name
                          xml.NameSuffix intake.spouse_suffix if intake.spouse_suffix.present?
                        end
                      end
                    when :qualifying_widow
                      yod = Date.parse(@submission.data_source.direct_file_data.spouse_date_of_death)&.strftime("%Y")
                      xml.QualWidOrWider do
                        xml.QualWidOrWiderSurvCuPartner 'X'
                        if yod == Time.now.year - 1
                          xml.LastYear 'X'
                        elsif yod == Time.now.year - 2
                          xml.TwoYearPrior 'X'
                        end
                      end
                    when :single, :married_filing_jointly, :head_of_household
                      xml.send(FILING_STATUS_ELEMENT[status], 'X')
                    else
                      raise "Filing status not found"
                    end
                  end
                  
                  xml.Exemptions do
                    xml.YouRegular "X"
                    # xml.SpouseCuRegular
                    # xml.DomesticPartnerRegular
                    # xml.YouOver65
                    # xml.SpouseCuPartner65OrOver
                    # xml.YouBlindOrDisabled
                    # xml.SpouseCuPartnerBlindOrDisabled
                    # xml.YouVeteran
                    # xml.SpouseCuPartnerVeteran
                    xml.NumOfQualiDependChild qualifying_dependents.count(&:qualifying_child?)
                    xml.NumOfOtherDepend qualifying_dependents.count(&:qualifying_relative?)
                    # xml.DependAttendCollege
                    # # Add lines 6-12
                    # xml.TotalExemptionAmountA
                  end

                  # xml.NjOtherTaxYearBeginDate
                  # xml.NjOtherTaxYearEndDate
                  # xml.NjResidentStatusFromDate
                  # xml.NjResidentStatusToDate
                  # xml.FiscalMonth

                  unless intake.dependents.empty?
                    xml.Dependents do
                      # TODO: Should this be qualifying dependents? Or all dependents?
                      intake.dependents.each do |dependent|
                        xml.DependentsName do 
                          xml.FirstName dependent.first_name
                          xml.MiddleInitial dependent.middle_initial if dependent.middle_initial.present?
                          xml.LastName dependent.last_name
                          xml.NameSuffix dependent.suffix if dependent.suffix.present?
                        end
                        xml.DependentsSSN dependent.ssn
                        # xml.BirthYear
                        # xml.NoHealthInsurance
                      end
                    end
                  end

                  puts intake.residence_county
                  puts intake.residence_county_code
                  xml.CountyCode intake.residence_county_code

                  # xml.NactpCode '12345' #???
                end
                
                xml.Body do
                  # xml.WagesSalariesTips
                  xml.TaxableInterestIncome intake.fed_taxable_income
                  # xml.TaxexemptInterestIncome
                  # xml.Dividends
                  # xml.NetProfitsFromBusiness
                  # xml.NetGainsDisposOfProperty
                  # xml.PensAnnuitAndIraWithdraw
                  # xml.TaxExemptPensAnnuit
                  # xml.DistribShareOfPartshipInc
                  # xml.NetProRataShareOfScorpIncome
                  # xml.NetGainIncomRentsRoyalPatCopy
                  # xml.NetGamblingWinnings
                  # xml.AlimSepMaintPayReceived
                  # xml.Other do
                  #   xml.NatureOfPrizeSource
                  #   xml.Amount
                  # end
                  # xml.TotalIncome
                  # xml.PensionExclusion
                  # xml.OtherRetireIncomeExclus
                  # xml.TotalExclusionAmount
                  # xml.GrossIncome
                  # xml.TotalExemptionAmountB
                  # xml.MedicalExpenses
                  # xml.AlimSepMaintPayments
                  # xml.QualifConserContribut
                  # xml.HealthenterpriseZoneDed
                  # xml.AltBusCalcAdjustment
                  # xml.OrganMarrowDeduction
                  # xml.NJBESTDed
                  # xml.NJCLASSDed
                  # xml.NJHigherEdDed
                  # xml.TotalExemptDeductions
                  # xml.TaxableIncome
                  # xml.PropertyTaxDeductOrCredit do
                  #   xml.TotalPropertyTaxPaid
                  #   xml.Homeowner
                  #   xml.Tenant
                  #   xml.Both
                  #   xml.PropertyTaxCredit
                  #   xml.PropertyTaxDeduction
                  # end
                end
              end
            end

            private

            def intake
              @submission.data_source
            end

            def calculated_fields
              @nj1040_fields ||= intake.tax_calculator.calculate
            end
          end
        end
      end
    end
  end
end