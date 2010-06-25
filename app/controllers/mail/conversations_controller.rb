class Mail::ConversationsController < ApplicationController
  include Mail::AccessControl
  
  before_filter :limit_access
  
  include_javascripts 'fullscreen', :only => [:index, :show]
  include_javascripts 'mail'
  include_stylesheets 'mail'
  exposure :title => 'subject', :columns => [:from, :last_message_recieved, :mailbox, :handled_by]
  
  def index
    case params[:category]
    when 'new':
      conditions = 'unread = true AND flag_closed = false'
    when 'mine':
      conditions = "handled_by = #{current_user.id} AND flag_closed = false"
    when 'open':
      conditions = "flag_closed = false"
    when 'closed':
      conditions = "flag_closed = true"
    when 'all':
      conditions = ''
    else
      params[:category] = 'new'
      conditions = 'unread = true AND flag_closed = false'
    end
    
    @records = Mail::ConversationsView.paginate(:all, :page => params[:page], :per_page => current_user.pagination_setting, :include => [:messages, :handler], :order => :updated_at, :conditions => conditions)

    @contacts = {}
    contacts = @records.collect {|c| c.messages.collect {|m| m.from_address}.select {|a| a != c.mailbox.address}.uniq}.flatten
    unless contacts.empty?
      contacts = contacts.collect {|c| "'#{c}'"}.join(', ')
      contacts = UsersView.find(:all, :conditions => "email IN (#{contacts})")
    
      contacts.each {|c| @contacts[c.email] = c}
    end
    
    super
  end
  
  def show
    redirect_to :index unless params[:id]
    @conversation = Mail::Conversation.find(params[:id], :include => [:handler])
    @messages = Mail::Message.find(:all, :conditions => "conversation_id = #{params[:id]}", :order => 'created_at ASC')
    load_mailboxes
  end
  
  def show_note
    redirect_to :index unless params[:id]
    @conversation = Mail::Conversation.find(params[:id])
  end
  
  def edit_note
    redirect_to :index unless params[:id]
    @conversation = Mail::Conversation.find(params[:id])
  end
  
  def update_note
    redirect_to :index unless params[:id] && params[:note]
    @conversation = Mail::Conversation.find(params[:id])
    @conversation.note = params[:note]
    @conversation.save
    
    render :action => 'show_note'
  end
  
  def close
    redirect_to :index unless params[:id]
    @conversation = Mail::Conversation.find(params[:id])
    @conversation.flag_closed = true
    @conversation.save
  end
  
  def reopen
    redirect_to :index unless params[:id]
    @conversation = Mail::Conversation.find(params[:id])
    @conversation.flag_closed = false
    @conversation.save
    
    @messages = Mail::Message.find(:all, :conditions => "conversation_id = #{params[:id]}", :order => 'created_at ASC')
    load_mailboxes
  end
  
  def move
    redirect_to :index unless params[:id] && params[:to]
    @conversation = Mail::Conversation.find(params[:id])
    @mailbox = Mail::Mailbox.find(params[:to])
    
    @conversation.mailbox_id = @mailbox.id
    @conversation.save
    
    load_mailboxes
  end
  
  private
  
  def load_mailboxes
    @mailboxes = {}
    Mail::Mailbox.find(:all).each {|mb| @mailboxes[mb.human_name] = mb.id }    
  end
end