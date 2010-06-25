class CreatePollAnswersView < ActiveRecord::Migration
  def self.up
    sql_script 'poll_answers_view_up'
  end

  def self.down
    sql_script 'poll_answers_view_down'
  end
end
