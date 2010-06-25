class CreateBundlesView < ActiveRecord::Migration
  def self.up
    sql_script 'bundles_view_up'
  end

  def self.down
    sql_script 'bundles_view_down'
  end
end
