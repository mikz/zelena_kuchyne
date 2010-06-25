class CreateCars < ActiveRecord::Migration
  def self.up
    sql_script 'cars_up'
  end

  def self.down
    sql_script 'cars_down'
  end
end
