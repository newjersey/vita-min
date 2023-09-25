require "rails_helper"
require_relative "../../../db/data/20230915164549_backfill_hashed_dependent_ssn"

describe "BackfillHashedDependentSsn" do
  let!(:dependent_with_ssn) { create :dependent, ssn: "123456789", hashed_ssn: nil }
  let!(:dependent_with_hashed_ssn) { create :dependent, ssn: "123456789", hashed_ssn: "1234567890847635" }
  let!(:dependent_without_ssn) { create :dependent, ssn: nil }

  context "with ssn and without hashed_ssn" do
    it "backfills hashed_ssn" do
      BackfillHashedDependentSsn.new.up

      dependent_with_ssn.reload
      expect(dependent_with_ssn.hashed_ssn).not_to be_nil
    end
  end

  context "with ssn and with hashed_ssn" do
    it "does not change" do
      expect do
        BackfillHashedDependentSsn.new.up
      end.not_to change { dependent_with_hashed_ssn.reload }
    end
  end

  context "without spouse_ssn" do
    it "remains nil" do
      expect do
        BackfillHashedDependentSsn.new.up
      end.not_to change { dependent_without_ssn.reload }

      expect(dependent_without_ssn.hashed_ssn).to be_nil
    end
  end
end