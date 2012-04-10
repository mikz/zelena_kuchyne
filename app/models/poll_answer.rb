# -*- encoding : utf-8 -*-
class PollAnswer < ActiveRecord::Base
  belongs_to :poll
  has_many :poll_votes
  belongs_to :result, :class_name => "PollAnswerView", :foreign_key => 'id'
  validates_length_of :text, :within => 1..100, :allow_nil => false
end

