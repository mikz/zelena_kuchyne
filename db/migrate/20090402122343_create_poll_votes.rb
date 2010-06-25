class CreatePollVotes < ActiveRecord::Migration
  def self.up
    sql_script 'poll_votes_up'
  end

  def self.down
    sql_script 'poll_votes_down'
  end
end
