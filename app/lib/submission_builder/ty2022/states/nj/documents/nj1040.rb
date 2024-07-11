module SubmissionBuilder
  module Ty2022
    module States
      module Nj
        module Documents
          class Nj1040 < SubmissionBuilder::Document
            include SubmissionBuilder::FormattingMethods

            def document
              build_xml_doc("NJ1040") do |xml|
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
 