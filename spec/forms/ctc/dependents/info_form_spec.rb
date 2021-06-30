require 'rails_helper'

describe Ctc::Dependents::InfoForm do
  let(:dependent) { create :dependent, intake: intake }
  let(:intake) { create :ctc_intake }
  let(:ssn) { nil }
  let(:tin_type) { "ssn_no_employment" }
  let(:params) do
    {
      ssn: ssn,
      tin_type: tin_type
    }
  end

  context "initialization with from_dependent" do
    let(:dependent) { create :dependent, intake: intake, ssn: ssn, tin_type: "ssn_no_employment" }
    context "coercing tin_type to the correct value when ssn_no_employment" do
      it "sets ssn_no_employment to yes, and primary_tin_type to ssn" do
        form = described_class.from_dependent(dependent)
        expect(form.tin_type).to eq "ssn"
        expect(form.ssn_no_employment).to eq "yes"
      end
    end
  end

  context "validations" do
    it "requires first and last name" do
      form = described_class.new(dependent, {})
      expect(form).not_to be_valid
      expect(form.errors.attribute_names).to include(:first_name)
      expect(form.errors.attribute_names).to include(:last_name)
    end

    it "requires relationship" do
      form = described_class.new(dependent, {})
      expect(form).not_to be_valid
      expect(form.errors.attribute_names).to include(:relationship)
    end

    it "requires birth date" do
      form = described_class.new(dependent, {})
      expect(form).not_to be_valid
      expect(form.errors.attribute_names).to include(:birth_date)

      form.assign_attributes(birth_date_month: '1', birth_date_day: '1', birth_date_year: 1.year.ago.year.to_s)
      form.valid?
      expect(form.errors.attribute_names).not_to include(:birth_date)
    end

    it "requires tin_type" do
      form = described_class.new(dependent, {})
      expect(form).not_to be_valid
      expect(form.errors.attribute_names).to include(:tin_type)
    end

    context "tin_type is atin" do
      let(:tin_type) { "atin" }
      let(:ssn) { "123456789" }

      it "requires valid atin number" do
        form = described_class.new(dependent, params)
        expect(form).not_to be_valid
        expect(form.errors.attribute_names).to include(:ssn)
      end
    end

    context "there is no tin/ssn entered" do
      let(:dependent) { create :dependent, intake: intake, tin_type: "ssn", ssn: nil }
      it "is not valid" do
        form = described_class.from_dependent(dependent)
        expect(form).not_to be_valid
        expect(form.errors.attribute_names).to include(:ssn)
      end
    end

    describe 'ssn_confirmation' do
      context 'if ssn was blank' do
        let(:ssn) { nil }

        it "is required" do
          form = described_class.from_dependent(dependent)
          form.assign_attributes(ssn: '555112222')
          expect(form).not_to be_valid
          expect(form.errors.attribute_names).to include(:ssn_confirmation)
        end
      end

      context 'if ssn was changed' do
        let(:ssn) { '555113333' }

        it "is required" do
          form = described_class.from_dependent(dependent)
          form.assign_attributes(ssn: '555112222')
          expect(form).not_to be_valid
          expect(form.errors.attribute_names).to include(:ssn_confirmation)
        end
      end

      context 'if ssn was not changed' do
        let(:dependent) { create :dependent, intake: intake, ssn:'555112222', tin_type: "ssn" }

        it "is not required" do
          form = described_class.from_dependent(dependent)
          form.assign_attributes(ssn: '555112222')
          form.valid?
          expect(form.errors.attribute_names).not_to include(:ssn_confirmation)
        end
      end
    end
  end

  describe '#save' do
    let(:intake) { build(:ctc_intake) }
    let(:params) do
      {
        first_name: 'Fae',
        last_name: 'Taxseason',
        suffix: 'Jr',
        birth_date_day: 1,
        birth_date_month: 1,
        birth_date_year: 1.year.ago.year,
        relationship: "daughter",
        full_time_student: "no",
        permanently_totally_disabled: "no",
        tin_type: tin_type,
        ssn_no_employment: ssn_no_employment,
        ssn: "123456789",
        ssn_confirmation: "123456789"
      }
    end
    let(:tin_type) { "ssn" }
    let(:ssn_no_employment) { "no" }

    it "saves the attributes on the dependent" do
      form = described_class.new(intake.dependents.new, params)
      expect(form).to be_valid
      form.save

      dependent = Dependent.last
      expect(dependent.first_name).to eq "Fae"
      expect(dependent.last_name).to eq "Taxseason"
      expect(dependent.suffix).to eq "Jr"
    end

    context "when tin type is ssn" do
      let(:tin_type) { "ssn" }
      context "when the ssn_no_employment checkbox is value yes" do
        let(:ssn_no_employment) { "yes" }

        it "has a resulting tin type of ssn_no_employment" do
          form = described_class.new(dependent, params)
          form.valid?
          form.save
          Dependent.last.tin_type = "ssn_no_employment"
        end
      end

      context "when the ssn_no_employment checkbox value is no" do
        let(:ssn_no_employment) { "no" }

        it "has a resulting tin type of ssn" do
          form = described_class.new(dependent, params)
          form.valid?
          form.save
          Dependent.last.tin_type = "ssn"
        end
      end
    end

    context "when tin type is not ssn" do
      let(:ssn_no_employment) { "no" }
      let(:tin_type) { "itin" }

      it "sets the tin type to itin" do
        form = described_class.new(dependent, params)
        form.valid?
        form.save
        Dependent.last.tin_type = "itin"
      end
    end
  end
end
