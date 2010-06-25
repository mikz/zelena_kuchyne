class CreateMailMessages < ActiveRecord::Migration
  def self.up
    sql_script 'mail_messages_up'
  end

  def self.down
    sql_script 'mail_messages_down'
  end
end
