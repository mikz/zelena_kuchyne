class CreateBundles < ActiveRecord::Migration
  def self.up
    sql_script 'bundles_up'
  end

  def self.down
    sql_script 'bundles_down'
  end
end
