module PdfFiller
  class Nj1040Pdf
    include PdfHelper

    def source_pdf_name
      "nj1040-TY2023"
    end

    def initialize(submission)
      @submission = submission

      # Most PDF fields are grabbed right off the XML
      builder = StateFile::StateInformationService.submission_builder_class(:nj)
      @xml_document = builder.new(submission).document
    end

    def hash_for_pdf
    end
  end
end
