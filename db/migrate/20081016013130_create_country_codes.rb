# -*- encoding : utf-8 -*-
class CreateCountryCodes < ActiveRecord::Migration
  def self.up
    sql_script 'country_codes_up'
  end

  def self.down
    sql_script 'country_codes_down'
  end
end

