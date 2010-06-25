class CreateMailConversationsViews < ActiveRecord::Migration
  def self.up
    sql_script 'mail_conversations_view_up'
  end

  def self.down
    sql_script 'mail_conversations_view_down'
  end
end
