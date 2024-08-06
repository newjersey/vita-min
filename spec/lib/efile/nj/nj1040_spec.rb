require 'rails_helper'

describe Efile::Nj::Nj1040 do
  let(:intake) { create(:state_file_nj_intake) }
  let!(:dependent) { intake.dependents.create(dob: 7.years.ago) }
  let(:instance) do
    described_class.new(
      year: MultiTenantService.statefile.current_tax_year,
      intake: intake
    )
  end

  # describe '#calculate_line_17' do
  #   it "adds up some of the prior lines" do
  #     expect(instance.calculate[:IT201_LINE_17]).to eq(35_151)
  #   end
  # end
end