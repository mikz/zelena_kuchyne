# -*- encoding : utf-8 -*-
class CreateCourses < ActiveRecord::Migration
  def self.up
    sql_script 'courses_up'
  end

  def self.down
    sql_script 'courses_down'
  end
end

