# == Schema Information
#
# Table name: team_member_roles
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  vita_partner_id :bigint
#
# Indexes
#
#  index_team_member_roles_on_vita_partner_id  (vita_partner_id)
#
# Foreign Keys
#
#  fk_rails_...  (vita_partner_id => vita_partners.id)
#
class TeamMemberRole < ApplicationRecord
  TYPE = "TeamMemberRole"

  belongs_to :legacy_vita_partner, foreign_key: "vita_partner_id", class_name: "VitaPartner", optional: true

  has_many :team_member_roles_vita_partners, dependent: :destroy
  has_many :vita_partners, through: :team_member_roles_vita_partners
  has_many :sites, through: :team_member_roles_vita_partners
  validate :has_site
  validate :all_sites_in_same_org

  scope :assignable_to_sites, -> (sites) {
    left_outer_joins(:sites).where(vita_partners: sites).or(where(legacy_vita_partner: sites))
  }

  def sites
    if vita_partner_id
      [VitaPartner.find(vita_partner_id)]
    else
      super
    end
  end

  def served_entities
    sites
  end

  private

  def has_site
    errors.add(:sites, "Must be associated to at least one site") if sites.blank? && legacy_vita_partner.blank?
  end

  def all_sites_in_same_org
    if sites.map(&:parent_organization).uniq.length > 1
      errors.add(:sites, "Must all be part of the same organization")
    end
  end
end
