class Mail::Message < ActiveRecord::Base
  belongs_to :conversation
  set_table_name 'mail_messages'
  set_primary_key 'message_id'

  def from
    if from_name && from_name != ''
      from_name
    else
      from_address
    end
  end
end
