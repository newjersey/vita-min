class AddNj1040ToStateFileNjIntakes < ActiveRecord::Migration[7.1]
  def change
    add_column :state_file_nj_intakes, :residence_county, :string
    add_column :state_file_nj_intakes, :residence_county_code, :string
  end
end
