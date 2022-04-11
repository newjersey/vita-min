module SubmissionBuilder
  module Ty2021
    class Return1040 < SubmissionBuilder::Shared::Return1040
      def self.attached_documents
        [
          SubmissionBuilder::Ty2021::Documents::Irs1040,
          SubmissionBuilder::Ty2021::Documents::Schedule8812
        ]
      end
    end
  end
end