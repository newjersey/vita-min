class AddArchivedToVitaPartner < ActiveRecord::Migration[6.0]
  def change
    add_column :vita_partners, :archived, :boolean, default: false
  end
end
