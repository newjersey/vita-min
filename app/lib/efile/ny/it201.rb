module Efile
  module Ny
    class It201
      def initialize(year:, filing_status:, claimed_as_dependent:, dependent_count:, lines:, it227:)
        @year = year

        @filing_status = filing_status # single, married_filing_jointly, that's all we support for now
        @claimed_as_dependent = claimed_as_dependent # true/false
        @dependent_count = dependent_count # number
        @computed = ActiveSupport::HashWithIndifferentAccess.new(lines)
        @it227 = it227
      end

      def calculate
        @computed[:AMT_60E] = @it227.calculate[:part2_line1]
        @computed[:AMT_17] = calculate_line_17
        @computed[:AMT_19] = calculate_line_19
        @computed[:AMT_24] = calculate_line_24
        @computed[:AMT_25] = @computed[:AMT_4]
        @computed[:AMT_27] = @computed[:AMT_15]
        @computed[:AMT_32] = calculate_line_32
        @computed[:AMT_33] = calculate_line_33
        @computed[:AMT_34] = calculate_line_34
        @computed[:AMT_35] = calculate_line_35
        @computed[:AMT_36] = @dependent_count
        @computed[:AMT_37] = calculate_line_37
        @computed[:AMT_38] = @computed[:AMT_37]
        @computed[:AMT_39] = calculate_line_39
        @computed[:AMT_43] = calculate_line_43
        @computed[:AMT_44] = calculate_line_44
        @computed[:AMT_46] = calculate_line_46
        @computed[:AMT_47] = calculate_line_47
        @computed[:AMT_47A] = calculate_line_47a
        @computed[:AMT_49] = calculate_line_49
        @computed[:AMT_52] = calculate_line_52
        @computed[:AMT_54] = calculate_line_54
        @computed[:AMT_54B] = calculate_line_54b
        @computed
      end

      private

      def calculate_line_17
        result = 0
        (1..16).each do |line_num|
          next if line_num == 12
          result += line_or_zero("AMT_#{line_num}")
        end

        result
      end

      def calculate_line_19
        line_or_zero(:AMT_17) - line_or_zero(:AMT_18).abs
      end

      def calculate_line_24
        result = 0
        result += line_or_zero(:AMT_19A)
        (20..23).each do |line_num|
          result += line_or_zero("AMT_#{line_num}")
        end
        result
      end

      def calculate_line_32
        result = 0
        (25..31).each do |line_num|
          result += line_or_zero("AMT_#{line_num}")
        end
        result
      end

      def calculate_line_33
        line_or_zero(:AMT_24) - line_or_zero(:AMT_32)
      end

      def calculate_line_34
        if filing_status_single?
          if @claimed_as_dependent
            3100
          else
            8000
          end
        elsif filing_status_mfj?
          16050
        end
      end

      def calculate_line_35
        result = line_or_zero(:AMT_33) - line_or_zero(:AMT_34)
        [result, 0].max
      end

      def calculate_line_37
        result = line_or_zero(:AMT_35) - (line_or_zero(:AMT_36) * 1000)
        [result, 0].max
      end

      def calculate_line_39
        # aka calctax
        1 # TODO
      end

      def calculate_line_43
        line_or_zero(:AMT_40) + line_or_zero(:AMT_41) + line_or_zero(:AMT_42)
      end

      def calculate_line_44
        [line_or_zero(:AMT_39) - line_or_zero(:AMT_43), 0].max
      end

      def calculate_line_46
        line_or_zero(:AMT_44) + line_or_zero(:AMT_45)
      end

      def calculate_line_47
        if full_year_nyc_resident?
          line_or_zero(:AMT_38)
        else
          0
        end
      end

      def calculate_line_47a
        if full_year_nyc_resident?
          nyc_tax_from_tables(@computed[:AMT_47])
        else
          0
        end
      end

      def calculate_line_49
        [line_or_zero(:AMT_47A) - line_or_zero(:AMT_48), 0].max
      end

      def calculate_line_52
        line_or_zero(:AMT_49) + line_or_zero(:AMT_50) + line_or_zero(:AMT_51)
      end

      def calculate_line_54
        [line_or_zero(:AMT_52) - line_or_zero(:AMT_53), 0].max
      end

      def calculate_line_54b
        (line_or_zero(:AMT_54A) * 0.0034).round
      end

      def nyc_tax_from_tables(amount)
        # TODO: Can this be extracted into a NYSTaxTables class, where it's a public method, and the
        # TaxTables class is instantiated with the filing status? That way it could be directly unit tested;
        # right now it can't be cleanly extracted due to the dependency on filing_status_mfj.
        #
        # I want to leave it in here until we have at least one more such tax table.
        row = Struct.new(:floor, :ceiling, :cumulative, :rate)
        table =
          if filing_status_mfj?
            [
              row.new(0, 21600, 0, 0.03078),
              row.new(21600, 45000, 665, 0.03762),
              row.new(45000, 90000, 1545, 0.03819),
              row.new(90000, 0, 3264, 0.03876)
            ]
          else
            [
              [0, 12000, 0, 0.03078],
              [12000, 25000, 369, 0.03762],
              [25000, 50000, 858, 0.03819],
              [50000, 0, 1813, 0.03876]
            ]
          end

        table_row = table.reverse.find do |table_row|
          amount > table_row.floor && (amount <= table_row.ceiling)
        end

        (table_row.cumulative + ((amount - table_row.floor) * table_row.rate)).round
      end

      def full_year_nyc_resident?
        if filing_status_mfj?
          if @computed["F_1_NBR"] == 12 && @computed["F_2_NBR"] == 12
            true
          end
        else
          @computed["F_1_NBR"] == 12
        end
      end

      def filing_status_mfj?
        @filing_status == :married_filing_jointly
      end

      def filing_status_single?
        @filing_status == :single
      end

      def line_or_zero(line)
        @computed[line] || 0
      end
    end
  end
end