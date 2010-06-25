class Mail::Mailbox < ActiveRecord::Base
  has_many :conversations, :include => [:messages, :handler]
  has_many :messages, :through => :conversations
  set_primary_key 'mailbox_id'
  set_table_name 'mail_mailboxes'
end
