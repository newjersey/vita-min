module SubmissionBuilder
  module Ty2022
    module States
      module Ny
        module Documents
          class RtnHeader < SubmissionBuilder::Document
            include SubmissionBuilder::FormattingMethods
            ACCOUNT_TYPES = {
              unfilled: 0,
              personal_checking: 1,
              personal_savings: 2,
              business_checking: 3,
              business_savings: 4
            }.freeze

            def document
              build_xml_doc("rtnHeader") do |xml|
                # xml.COND_CODE_1_NMBR
                # xml.COND_CODE_2_NMBR
                # xml.THRD_PRTY_DSGN_IND
                # xml.THRD_PRTY_PIN_NMBR
                xml.EXT_TP_ID claimed: @submission.data_source.primary.ssn
                unless @submission.data_source.routing_number.nil?
                  xml.ABA_NMBR claimed: @submission.data_source.routing_number unless @submission.data_source.routing_number.nil?
                end
                unless @submission.data_source.account_number.nil?
                  xml.BANK_ACCT_NMBR claimed: @submission.data_source.account_number.delete('-')
                end
                unless @submission.data_source.account_type.nil? || ACCOUNT_TYPES[@submission.data_source.account_type.to_sym] == 0
                  xml.ACCT_TYPE_CD claimed: ACCOUNT_TYPES[@submission.data_source.account_type.to_sym]
                end
                unless @submission.data_source.date_electronic_withdrawal.nil?
                  xml.ELC_AUTH_EFCTV_DT claimed: @submission.data_source.date_electronic_withdrawal
                end
                # xml.PYMT_AMT
                # xml.DCMT_RCVD_DT
                # xml.PSTMRK_DT
                xml.ACH_IND
                xml.RFND_OWE_IND
                xml.BAL_DUE_AMT claimed: calculated_fields.fetch(:IT201_LINE_80)
                # xml.SBMSN_ID
                # xml.ELF_STATE_ONLY_IND
                # xml.PREP_LN_1_ADR
                # xml.PREP_CTY_ADR
                xml.SOFT_VNDR_ID
                # xml.FIRM_NAME
                # xml.PP_NAME
                # xml.PREP_SIGN_DT
                # xml.PREP_LN_2_ADR
                # xml.PREP_ST_ADR
                # xml.PREP_ZIP_4_ADR
                # xml.PREP_ZIP_5_ADR
                # xml.PREP_EIN_IND
                # xml.AREACODE_NMBR
                # xml.EXCHNG_PHONE_NMBR
                # xml.DGT4_PHONE_NMBR
                xml.FORM_TYPE
                # xml.THRDPRTY_EMAIL_ADR
                # xml.EFIN_ID
                # xml.PP_PH_NMBR
                xml.IAT_IND
                # xml.ORIG_SBMSN_ID
                # xml.SP_DOB_DT # Tried to add this but filling it caused an error.
                # xml.FREE_FIL_IND
                # xml.PR_SSN_VALID_IND
                # xml.SP_SSN_VALID_IND
                # xml.BNK_ACCT_ACH_IND
                # xml.PAPER_CHK_RFND_IND
                # xml.ITIN_MSMTCH_IND
                # xml.IMPRFCT_RTN_IND
                # xml.DIR_DEP_IND
              end
            end

            private

            def calculated_fields
              @calculated_fields ||= @submission.data_source.tax_calculator.calculate
            end
          end
        end
      end
    end
  end
end
