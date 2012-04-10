# -*- encoding : utf-8 -*-
class CreateMailConversations < ActiveRecord::Migration
  def self.up
    sql_script 'mail_conversations_up'
  end

  def self.down
    sql_script 'mail_conversations_down'
  end
end

