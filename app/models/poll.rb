# -*- encoding : utf-8 -*-
class Poll < ActiveRecord::Base
  has_many :poll_answers, :order => "id"
  has_many :poll_answers_results, :class_name => "PollAnswerView", :order => "id"
  has_many :poll_votes, :through => :poll_answers
  after_save :save_answers
  validates_associated :poll_answers
  validates_length_of :question, :within => 4..100
  validates_inclusion_of :poll_type, :in => %w( single multi )
  validates_presence_of :poll_type,:question,:poll_answers
  
  def answers=(vals=[])
    answers = vals.map do |val|
        self.poll_answers.new(:text => val)
    end
    self.poll_answers=(answers)
  end
  
  
  def answer_count
    self.poll_answers.size
  end
  
  def max_percent
    max = 0
    self.poll_answers_results.each do |answer|
      max = answer.percent if answer.percent > max
    end
    max
  end
  
  
  def can_vote?(user)
    (self.poll_vote_ids & user.poll_vote_ids).empty?
  end
  
  protected
  def save_answers
    self.poll_answers.each { |answer|
      answer.save
    }
  end
end

