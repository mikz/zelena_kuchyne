class CreatePollAnswers < ActiveRecord::Migration
  def self.up
    sql_script 'poll_answers_up'
  end

  def self.down
    sql_script 'poll_answers_down'
  end
end
