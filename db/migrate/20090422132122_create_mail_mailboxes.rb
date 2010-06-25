class CreateMailMailboxes < ActiveRecord::Migration
  def self.up
    sql_script 'mail_mailboxes_up'
  end

  def self.down
    sql_script 'mail_mailboxes_down'
  end
end
