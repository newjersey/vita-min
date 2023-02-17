Rails.application.reloader.to_prepare do
  begin
    if ActiveRecord::Base.connection.table_exists?(:experiments)
      ExperimentService.ensure_experiments_exist_in_database
    end
  rescue ActiveRecord::NoDatabaseError
  end
end