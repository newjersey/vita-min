# frozen_string_literal: true
module SubmissionBuilder
  module Ty2022
    module States
      module Ny
        class IndividualReturn < SubmissionBuilder::Document
          def document
            document = build_xml_doc('efile:ReturnState')
            document.at("ReturnState").add_child(authentication_header)
            document.at("ReturnState").add_child(return_header)
            document.at("ReturnState").add_child("<ReturnDataState></ReturnDataState>")
            document.at("ReturnDataState").add_child(documents_wrapper)
            attached_documents.each do |attached|
              document.at('forms').add_child(document_fragment(attached))
            end
            document
          end

          def self.state_abbreviation
            "NY"
          end

          def self.return_type
            "IT201"
          end

          def pdf_documents
            included_documents.map { |item| item if item.pdf }.compact
          end

          private

          def documents_wrapper
            xml_doc = build_xml_doc("efile:processBO") do |xml|
              xml.filingKeys do
                xml.SOURCE_CD ""
                xml.EXT_TP_ID @submission.data_source.primary.ssn
                xml.LIAB_PRD_BEG_DT Date.new(@submission.data_source.tax_return_year).beginning_of_year
                xml.LIAB_PRD_END_DT Date.new(@submission.data_source.tax_return_year).end_of_year
                xml.TAX_YEAR @submission.data_source.tax_return_year
              end

              xml.tiPrime do
                xml.FIRST_NAME @submission.data_source.primary.first_name
                xml.MI_NAME @submission.data_source.primary.middle_initial
                xml.LAST_NAME @submission.data_source.primary.last_name
                xml.MAIL_LN_2_ADR @submission.data_source.direct_file_data.mailing_street
                xml.MAIL_CITY_ADR @submission.data_source.direct_file_data.mailing_city
                xml.MAIL_STATE_ADR @submission.data_source.direct_file_data.mailing_state
                xml.MAIL_ZIP_5_ADR @submission.data_source.direct_file_data.mailing_zip
                # TODO: do we need county code? what about other school district fields?
                # xml.COUNTY_CD @submission.data_source.residence_county
                xml.COUNTY_NAME @submission.data_source.residence_county
                xml.PERM_LN_1_ADR @submission.data_source.permanent_street
                xml.PERM_CTY_ADR @submission.data_source.permanent_city
                xml.PERM_ST_ADR "NY" # TODO: make sure we do want to hardcode this
                xml.PERM_ZIP_ADR @submission.data_source.permanent_zip
                xml.SCHOOL_CD @submission.data_source.school_district_number
                xml.SCHOOL_NAME @submission.data_source.school_district
                xml.COUNTRY_NAME @submission.data_source.mailing_country
              end

              if @submission.data_source.filing_status_mfj? || @submission.data_source.filing_status_mfs?
                xml.tiSpouse do
                  xml.FIRST_NAME @submission.data_source.spouse.first_name
                  xml.MI_NAME @submission.data_source.spouse.middle_initial
                  xml.LAST_NAME @submission.data_source.spouse.last_name
                  xml.SP_SSN_NMBR @submission.data_source.spouse.ssn
                  xml.SP_EMP_DESC @submission.data_source.direct_file_data.spouse_occupation
                end
              end

              @submission.data_source.dependents.where(eic_qualifying: true).each_with_index do |dependent, index|
                xml.dependent do
                  xml.DEP_SSN_NMBR dependent.ssn
                  xml.DEP_SEQ_NMBR index+1
                  xml.DEP_DISAB_IND dependent.eic_disability == true ? 1 : 2
                  xml.DEP_FORM_ID 215
                  xml.DEP_RELATION_DESC dependent.relationship
                  xml.DEP_STUDENT_IND dependent.eic_student == true ? 1 : 2
                  xml.DEP_CHLD_LAST_NAME dependent.last_name
                  xml.DEP_CHLD_FRST_NAME dependent.first_name
                  xml.DEP_CHLD_MI_NAME dependent.middle_initial
                  xml.DEP_CHLD_SFX_NAME dependent.suffix
                  xml.DEP_MNTH_LVD_NMBR dependent.months_in_home
                  xml.DOB_DT dependent.dob&.strftime("%Y-%m-%d")
                end
              end

              xml.composition do
                xml.forms
              end
            end

            xml_doc.at('*')
          end

          def document_fragment(document)
            document[:xml_class].build(@submission, validate: false, kwargs: document[:kwargs]).document.at("*")
          end

          def authentication_header
            SubmissionBuilder::Ty2022::States::AuthenticationHeader.build(@submission, validate: false).document.at("*")
          end

          def return_header
            SubmissionBuilder::Ty2022::States::ReturnHeader.build(@submission, validate: false).document.at("*")
          end

          def schema_file
            File.join(Rails.root, "vendor", "us_states", "unpacked", "NYSIndividual2023V3.0", "Common", "NysReturnState.xsd")
          end

          def attached_documents
            @attached_documents ||= xml_documents.map { |doc| { xml_class: doc.xml, kwargs: doc.kwargs } }
          end

          def xml_documents
            included_documents.map { |item| item if item.xml }.compact
          end

          def included_documents
            supported_documents.map { |item| OpenStruct.new(**item, kwargs: item[:kwargs] || {}) if item[:include] }.compact
          end

          def supported_documents
            tax_calculator = @submission.data_source.tax_calculator
            calculated_fields = tax_calculator.calculate
            receiving_213_credit = calculated_fields[:IT213_LINE_14].present? && calculated_fields[:IT213_LINE_14] > 0
            receiving_214_credit = calculated_fields[:IT214_LINE_33].present? && calculated_fields[:IT214_LINE_33] > 0
            supported_docs = [
              {
                xml: SubmissionBuilder::Ty2022::States::Ny::Documents::RtnHeader,
                pdf: nil,
                include: true
              },
              {
                xml: SubmissionBuilder::Ty2022::States::Ny::Documents::It201,
                pdf: PdfFiller::Ny201Pdf,
                include: true
              },
              {
                xml: SubmissionBuilder::Ty2022::States::Ny::Documents::It213,
                pdf: PdfFiller::Ny213Pdf,
                include: receiving_213_credit
              },
              {
                xml: SubmissionBuilder::Ty2022::States::Ny::Documents::It214,
                pdf: PdfFiller::Ny214Pdf,
                include: receiving_214_credit
              },
              {
                xml: SubmissionBuilder::Ty2022::States::Ny::Documents::It215,
                pdf: PdfFiller::Ny215Pdf,
                include: true
              },
              {
                xml: nil,
                pdf: PdfFiller::NyTr579ItPdf,
                include: true
              }
            ]
            @submission.data_source.state_file1099_gs.each do |form1099g|
              supported_docs << {
                xml: SubmissionBuilder::Ty2022::States::Ny::Documents::State1099G,
                pdf: nil,
                include: true,
                kwargs: { form1099g: form1099g }
              }
            end
            supported_docs
          end
        end
      end
    end
  end
end