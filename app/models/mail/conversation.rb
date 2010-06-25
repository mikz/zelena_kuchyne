class Mail::Conversation < ActiveRecord::Base
  belongs_to :mailbox
  has_many :messages
  belongs_to :handler, :class_name => "User", :foreign_key => 'handled_by'
  set_table_name 'mail_conversations'
  set_primary_key 'conversation_id'
  
  def with
    messages.select {|m| m.direction == 'recieved' }.collect {|m| {:address => m.from_address, :name => m.from_name}}.uniq
  end
  
  def subject
    messages.first.subject
  end

  def last_message_recieved
    messages.last.created_at
  end
end
