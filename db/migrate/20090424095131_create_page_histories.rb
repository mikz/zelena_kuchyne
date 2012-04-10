# -*- encoding : utf-8 -*-
class CreatePageHistories < ActiveRecord::Migration
  def self.up
    sql_script 'page_histories_up'
  end

  def self.down
    sql_script 'page_histories_down'
  end
end

