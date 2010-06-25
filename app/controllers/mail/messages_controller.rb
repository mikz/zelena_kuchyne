class Mail::MessagesController < ApplicationController
  include Mail::AccessControl
  
  include_stylesheets 'mail'

  def index
    redirect_to :controller => '/mail/conversations'
  end
  
  def show
    redirect_to :controller => '/mail/conversations' unless params[:id]
    @message = Mail::Message.find(params[:id])
  end
  
  def details
    show
  end

  def reply
    redirect_to :controller => '/mail/conversations' unless params[:id]
    @message = Mail::Message.find(params[:id])
    raise ArgumentError, "Cannot reply to yourself" if (Mail::Mailbox.find_by_address(@message.from_address))
  end

  def send_reply
    
  end
  
  # this is more difficult than it seems, we also have to update the conversation line to reflect the change, 
  # which means do almost everything the ConversationController.index and ConversationController.show do 
  # when rendering the conversation list
  def toggle_read
    redirect_to :controller => '/mail/conversations' unless params[:id]
    @message = Mail::Message.find(params[:id], :include => :conversation)
    @message.flag_new = !@message.flag_new
    @message.conversation.handler = current_user if @message.conversation.handler.nil?
    @message.conversation.save
    @message.save
    
    # data for conversation line
    @conversation = Mail::ConversationsView.find(@message.conversation_id)
    contacts = @conversation.messages.collect {|m| m.from_address}.select {|a| a != @conversation.mailbox.address}.uniq
    
    @contacts = {}
    unless contacts.empty?
      contacts = contacts.collect {|c| "'#{c}'"}.join(', ')
      contacts = UsersView.find(:all, :conditions => "email IN (#{contacts})")
      
      contacts.each {|c| @contacts[c.email] = c}
    end
  end
end
