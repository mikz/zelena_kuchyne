# -*- encoding : utf-8 -*-
class CreateNews < ActiveRecord::Migration
  def self.up
    sql_script 'news_up'
  end

  def self.down
    sql_script 'news_down'
  end
end

