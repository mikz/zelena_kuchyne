class PollVote < ActiveRecord::Base
  validates_presence_of :user
  
  belongs_to :poll_answer
  belongs_to :user
  
  def validate
    unless UserSystem.logged_in?
      self.errors.add_to_base "Hlasovat mohou jen registrovaní uživatelé."
      return
    end
  end
  
  def poll
    self.poll_answer.poll
  end
end
