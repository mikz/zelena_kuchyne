# -*- encoding : utf-8 -*-
class CreateUserTokens < ActiveRecord::Migration
  def self.up
    sql_script 'user_tokens_up'
  end

  def self.down
    sql_script 'user_tokens_down'
  end
end

