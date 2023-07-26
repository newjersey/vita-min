# == Schema Information
#
# Table name: faq_categories
#
#  id         :bigint           not null, primary key
#  name_en    :string
#  name_es    :string
#  position   :integer
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class FaqCategory < ApplicationRecord
  has_many :faq_items, -> { order(position: :asc) }
  acts_as_list
  has_paper_trail on: [:create, :destroy, :update]
  default_scope { order(position: :asc) }

  def name(locale)
    case locale
    when :en
      name_en
    when :es
      name_es
    end
  end
end