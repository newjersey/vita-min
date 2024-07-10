# frozen_string_literal: true
module SubmissionBuilder
  module Ty2022
    module States
      module Nj
        class IndividualReturn < StateReturn

          def document
            # document = build_xml_doc('efile:ReturnState', stateSchemaVersion: "AZIndividual2023v1.0")
            # document
          end

          def pdf_documents
            # included_documents.map { |item| item if item.pdf }.compact
          end
        end
      end
    end
  end
end