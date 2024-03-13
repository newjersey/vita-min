module SubmissionBuilder
  module Ty2022
    module States
      module Az
        module Documents
          class State1099G < SubmissionBuilder::Document
            include SubmissionBuilder::FormattingMethods

            def document
              form1099g = @kwargs[:form1099g]

              build_xml_doc("State1099G", documentId: "State1099G-#{form1099g.id}") do |xml|
                if form1099g.payer_name && form1099g.payer_name != ''
                  xml.PayerName payerNameControl: form1099g.payer_name.gsub(/\s+/, '').upcase[0..3] do
                    xml.BusinessNameLine1Txt form1099g.payer_name.gsub(/\s+/, ' ')&.slice(0, 75)&.strip
                  end
                  xml.PayerUSAddress do
                    xml.AddressLine1Txt form1099g.payer_street_address.gsub(/\s+/, ' ')&.slice(0, 35)&.strip
                    xml.CityNm form1099g.payer_city.gsub(/\s+/, ' ')&.slice(0, 22)&.strip
                    xml.StateAbbreviationCd "AZ"
                    xml.ZIPCd form1099g.payer_zip
                  end
                  xml.PayerEIN form1099g.payer_tin
                end
                recipient = if form1099g.recipient_primary?
                  form1099g.intake.primary
                elsif form1099g.recipient_spouse?
                  form1099g.intake.spouse
                end
                xml.RecipientSSN recipient.ssn
                xml.RecipientName recipient.full_name.gsub(/\s+/, ' ')&.strip
                xml.RecipientUSAddress do
                  xml.AddressLine1Txt form1099g.recipient_address_line1.gsub(/\s+/, ' ')&.slice(0, 35)&.strip
                  xml.AddressLine2Txt form1099g.recipient_address_line2.gsub(/\s+/, ' ')&.slice(0, 35)&.strip if form1099g.recipient_address_line2.present?
                  xml.CityNm form1099g.recipient_city.gsub(/\s+/, ' ')&.slice(0, 22)&.strip
                  xml.StateAbbreviationCd "AZ"
                  xml.ZIPCd form1099g.recipient_zip
                end
                xml.UnemploymentCompensation form1099g.unemployment_compensation
                xml.FederalTaxWithheld form1099g.federal_income_tax_withheld
                xml.State1099GStateLocalTaxGrp do
                  xml.StateTaxWithheldAmt form1099g.state_income_tax_withheld
                  xml.StateAbbreviationCd "AZ"
                  if form1099g.state_identification_number && form1099g.state_identification_number != ''
                    xml.PayerStateIdNumber form1099g.state_identification_number
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
