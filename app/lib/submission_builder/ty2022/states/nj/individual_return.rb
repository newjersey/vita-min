# frozen_string_literal: true
module SubmissionBuilder
  module Ty2022
    module States
      module Nj
        class IndividualReturn < StateReturn

          private

          def attached_documents_parent_tag
            # This is different for NY and AZ - what is it for NJ?
            # 'forms'
          end

          def build_xml_doc_tag
            # This is different for NY and AZ - what is it for NJ?
            # "ReturnState"
          end

          def schema_file
            SchemaFileLoader.load_file("us_states", "unpacked", "NJIndividual2023V0.4", "NJIndividual", "IndividualReturnNJ1040.xsd")
          end

          def supported_documents
            supported_docs = []
            tax_calculator = @submission.data_source.tax_calculator
            calculated_fields = tax_calculator.calculate
            # supported_docs = [
            #   {
            #     xml: SubmissionBuilder::Ty2022::States::Nj::Documents::Nj1040,
            #     pdf: PdfFiller::Nj1040Pdf,
            #     include: true
            #   },
            # ]

            supported_docs += combined_w2s
            supported_docs += form1099gs
            supported_docs
          end
        end
      end
    end
  end
end