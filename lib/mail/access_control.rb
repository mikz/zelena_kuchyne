module Mail::AccessControl

  def self.included(base)
    base.helper_method :can_reply_to
  end
  
  def limit_access
    # TODO raise AcessDenied if current user has access to none of mailboxes
  end
  
  # TODO - find some better way to check user rights then these methods
  
  def can_reply_to(conversation)
    true
  end
  
  def can_admin(mailbox)
    true
  end
end