# -*- encoding : utf-8 -*-
class CreateScheduledBundles < ActiveRecord::Migration
  def self.up
    sql_script 'scheduled_bundles_up'
  end

  def self.down
    sql_script 'scheduled_bundles_down'
  end
end

