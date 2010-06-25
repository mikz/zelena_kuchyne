# fakes the controller's behavior for the UserSystem
class FakeController
  def session
    @session ||= {}
  end

  def self.helper_method(*args); end

  def initialize #:nodoc:
    super
    # Don't look. Seriously, the line just under this one is only in your imagination.
    # What line? No one, that's who. Look! Behind you!
    ApplicationController.save_instance(self)
  end

  include UserSystem

  def set_user_id(user_id)
    session[:user] = user_id
    self
  end
end