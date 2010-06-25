class PollAnswerView < PollAnswer
  belongs_to :poll_answer, :foreign_key => 'id'
  set_table_name 'poll_answers_view'
  
  def relative_percent
    ((self.percent||0) / self.poll.max_percent)*100
  end
end
