class Mail::ConversationsView < ActiveRecord::Base
  belongs_to :mailbox
  has_many :messages, :foreign_key => 'conversation_id'
  belongs_to :handler, :class_name => 'User', :foreign_key => 'handled_by'
  set_table_name 'mail_conversations_view'
  set_primary_key 'conversation_id'
  
end
