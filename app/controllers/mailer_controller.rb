require 'digest/md5'

class MailerController < ApplicationController
  before_filter(:except => [:send_forgotten_password]) { |c| c.must_belong_to_one_of(:admins)}
  
  def send_forgotten_password
    if params[:user]['login_or_email'] =~ /^[a-z0-9\.\_\%\+\-]+@[a-z0-9\-\.\_]+\.[a-z]{2,4}$/i
      @user = User.find_by_email params[:user]['login_or_email']
    else
      @user = User.find_by_login params[:user]['login_or_email']
    end
    if @user
      UserToken.delete_all ["user_id = ?", @user.id]
      UserToken.create(:token => Digest::MD5.hexdigest(Time.now.to_s), :user => @user)
      Mailer.deliver_forgotten_password(@user)
      redirect_to "/#{locales[:forgotten_password_sent]}"
    else
      flash[:notice] = locales[:user_not_found]
      redirect_to :back
    end
  end
end
