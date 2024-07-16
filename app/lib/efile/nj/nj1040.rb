module Efile
  module Nj
    class Nj1040 < ::Efile::TaxCalculator
      attr_reader :lines

      def initialize(year:, intake:, include_source: false)
        @year = year
        @intake = intake
        @filing_status = intake.filing_status.to_sym # single, married_filing_jointly, that's all we support for now
        @direct_file_data = intake.direct_file_data
        intake.state_file_w2s.each do |w2|
          dest_w2 = @direct_file_data.w2s[w2.w2_index]
          dest_w2.node.at("W2StateLocalTaxGrp").inner_html = w2.state_tax_group_xml_node
        end
        @eligibility_lived_in_state = intake.eligibility_lived_in_state
        @dependent_count = intake.dependents.length

        @value_access_tracker = Efile::ValueAccessTracker.new(include_source: include_source)
        @lines = HashWithIndifferentAccess.new
      end

      def calculate
        @lines.transform_values(&:value)
      end

      def refund_or_owed_amount
        #refund if amount is positive, owed if amount is negative
      #   line_or_zero(:IT201_LINE_76) - line_or_zero(:IT201_LINE_62)
        0
      end

      def analytics_attrs
        {
        }
      end

      private

      # TODO: add methods to calc each line
    end
  end
end