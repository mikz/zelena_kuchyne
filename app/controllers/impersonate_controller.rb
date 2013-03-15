class ImpersonateController < ApplicationController
  def create
    self.current_user = user
    flash[:notice] = t(:impersonated, user: user.login)
    redirect_to '/'
  end

  protected
  def user
    User.find(params[:id])
  end
end
