require 'rails_helper'

describe Efile::Az::Az140 do
  let(:intake) { create(:state_file_az_intake, eligibility_lived_in_state: 1) }
  let!(:dependent) { intake.dependents.create(dob: 7.years.ago) }
  let(:instance) do
    described_class.new(
      year: MultiTenantService.statefile.current_tax_year,
      intake: intake
    )
  end

  describe 'Line 56 Increased Excise Tax Credit' do
    context 'when the client does not have a valid SSN because it is not present' do
      before do
        intake.direct_file_data.primary_ssn = nil
        intake.direct_file_data.filing_status = 1 # single
        intake.direct_file_data.fed_agi = 12_500 # qualifying agi
        intake.direct_file_data.total_exempt_primary_spouse = 1 # not claimed as a dependent
        intake.was_incarcerated = 2 # no
      end

      it 'sets the amount to 0 because the client does not qualify' do
        instance.calculate
        expect(instance.lines[:AZ140_LINE_56].value).to eq(0)
      end
    end
  end

  context 'when the client does not have a valid SSN because it starts with 9' do
    before do
      intake.direct_file_data.primary_ssn = '999999999' # invalid
      intake.direct_file_data.filing_status = 1 # single
      intake.direct_file_data.fed_agi = 12_500 # qualifying agi
      intake.direct_file_data.total_exempt_primary_spouse = 1 # not claimed as a dependent
      intake.was_incarcerated = 2 # no
    end

    it 'sets the amount to 0 because the client does not qualify' do
      instance.calculate
      expect(instance.lines[:AZ140_LINE_56].value).to eq(0)
    end
  end

  context 'when the client has been claimed as a dependent' do
    before do
      intake.direct_file_data.primary_ssn = '555002222' # valid
      intake.direct_file_data.filing_status = 1 # single
      intake.direct_file_data.fed_agi = 12_500 # qualifying agi
      intake.direct_file_data.total_exempt_primary_spouse = 0 # claimed as a dependent
      intake.was_incarcerated = 2 # no
    end

    it 'sets the amount to 0 because the client does not qualify' do
      instance.calculate
      expect(instance.lines[:AZ140_LINE_56].value).to eq(0)
    end
  end

  context 'when the client was incarcerated for more than 60 days' do
    before do
      intake.direct_file_data.primary_ssn = '555002222' # valid
      intake.direct_file_data.filing_status = 1 # single
      intake.direct_file_data.fed_agi = 12_500 # qualifying agi
      intake.direct_file_data.total_exempt_primary_spouse = 1 # not claimed as a dependent
      intake.was_incarcerated = 1 # yes
    end

    it 'sets the amount to 0 because the client does not qualify' do
      instance.calculate
      expect(instance.lines[:AZ140_LINE_56].value).to eq(0)
    end
  end

  context 'when the client has too much income and is filing single' do
    before do
      intake.direct_file_data.primary_ssn = '555002222' # valid
      intake.direct_file_data.filing_status = 1 # single
      intake.direct_file_data.fed_agi = 12_501 # disqualifying agi
      intake.direct_file_data.total_exempt_primary_spouse = 1 # not claimed as a dependent
      intake.was_incarcerated = 2 # no
    end

    it 'sets the amount to 0 because the client does not qualify' do
      instance.calculate
      expect(instance.lines[:AZ140_LINE_56].value).to eq(0)
    end
  end

  context 'when the client has too much income and is filing mfs' do
    before do
      intake.direct_file_data.primary_ssn = '555002222' # valid
      intake.direct_file_data.filing_status = 3 # mfs
      intake.direct_file_data.fed_agi = 12_501 # disqualifying agi
      intake.direct_file_data.total_exempt_primary_spouse = 1 # not claimed as a dependent
      intake.was_incarcerated = 2 # no
    end

    it 'sets the amount to 0 because the client does not qualify' do
      instance.calculate
      expect(instance.lines[:AZ140_LINE_56].value).to eq(0)
    end
  end

  context 'when the client has too much income and is filing mfj' do
    before do
      intake.direct_file_data.primary_ssn = '555002222' # valid
      intake.direct_file_data.filing_status = 2 # mfj
      intake.direct_file_data.fed_agi = 25_001 # disqualifying agi
      intake.direct_file_data.total_exempt_primary_spouse = 1 # not claimed as a dependent
      intake.was_incarcerated = 2 # no
    end

    it 'sets the amount to 0 because the client does not qualify' do
      instance.calculate
      expect(instance.lines[:AZ140_LINE_56].value).to eq(0)
    end
  end

  context 'when the client has too much income and is filing hoh' do
    before do
      intake.direct_file_data.primary_ssn = '555002222' # valid
      intake.direct_file_data.filing_status = 4 # hoh
      intake.direct_file_data.fed_agi = 25_001 # disqualifying agi
      intake.direct_file_data.total_exempt_primary_spouse = 1 # not claimed as a dependent
      intake.was_incarcerated = 2 # no
    end

    it 'sets the amount to 0 because the client does not qualify' do
      instance.calculate
      expect(instance.lines[:AZ140_LINE_56].value).to eq(0)
    end
  end

  context 'when the client qualifies for the credit and is filing single' do
    before do
      intake.direct_file_data.primary_ssn = '555002222' # valid
      intake.direct_file_data.filing_status = 1 # single
      intake.direct_file_data.fed_agi = 12_500 # qualifying agi
      intake.direct_file_data.total_exempt_primary_spouse = 1 # not claimed as a dependent
      intake.was_incarcerated = 2 # no
    end

    it 'sets the credit to the correct amount' do
      instance.calculate
      expect(instance.lines[:AZ140_LINE_56].value).to eq(50) # (1 filer + 1 dependent) * 25
    end
  end

  context 'when the client qualifies for the credit and is filing mfs' do
    before do
      intake.direct_file_data.primary_ssn = '555002222' # valid
      intake.direct_file_data.filing_status = 3 # mfs
      intake.direct_file_data.fed_agi = 12_500 # qualifying agi
      intake.direct_file_data.total_exempt_primary_spouse = 1 # not claimed as a dependent
      intake.was_incarcerated = 2 # no
    end

    it 'sets the credit to the correct amount' do
      instance.calculate
      expect(instance.lines[:AZ140_LINE_56].value).to eq(50) # (1 filer + 1 dependent) * 25
    end
  end

  context 'when the client qualifies for the credit and is filing mfj' do
    before do
      intake.direct_file_data.primary_ssn = '555002222' # valid
      intake.direct_file_data.filing_status = 2 # mfj
      intake.direct_file_data.fed_agi = 25_000 # qualifying agi
      intake.direct_file_data.total_exempt_primary_spouse = 1 # not claimed as a dependent
      intake.was_incarcerated = 2 # no
    end

    it 'sets the credit to the correct amount' do
      instance.calculate
      expect(instance.lines[:AZ140_LINE_56].value).to eq(75) # (2 filers + 1 dependent) * 25
    end
  end

  context 'when the client qualifies for the credit and is filing hoh' do
    before do
      intake.direct_file_data.primary_ssn = '555002222' # valid
      intake.direct_file_data.filing_status = 4 # hoh
      intake.direct_file_data.fed_agi = 25_000 # # qualifying agi
      intake.direct_file_data.total_exempt_primary_spouse = 1 # not claimed as a dependent
      intake.was_incarcerated = 2 # no
    end

    it 'sets the credit to the correct amount' do
      instance.calculate
      expect(instance.lines[:AZ140_LINE_56].value).to eq(50) # (1 filer + 1 dependent) * 25
    end
  end

  context 'when the client qualifies for the maximum credit' do
    before do
      intake.direct_file_data.primary_ssn = '555002222' # valid
      intake.direct_file_data.filing_status = 1 # single
      intake.direct_file_data.fed_agi = 12_500 # qualifying agi
      intake.direct_file_data.total_exempt_primary_spouse = 1 # not claimed as a dependent
      intake.was_incarcerated = 2 # no
      intake.dependents.create(dob: 5.years.ago)
      intake.dependents.create(dob: 3.years.ago)
      intake.dependents.create(dob: 1.years.ago)
    end

    it 'sets the credit to the maximum amount' do
      instance.calculate
      expect(instance.lines[:AZ140_LINE_56].value).to eq(100) # (1 filer + 4 dependents) * 25 = 125 but max is 100
    end
  end
end