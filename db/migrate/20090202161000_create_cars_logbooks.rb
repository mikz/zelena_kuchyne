# -*- encoding : utf-8 -*-
class CreateCarsLogbooks < ActiveRecord::Migration
  def self.up
    sql_script 'cars_logbooks_up'
  end

  def self.down
    sql_script 'cars_logbooks_down'
  end
end

