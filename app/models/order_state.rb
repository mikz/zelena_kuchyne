class OrderState < ActiveRecord::Base
  has_many :orders
  belongs_to :next_state, :class_name => 'OrderState', :foreign_key => 'next_state'
  belongs_to :previous_state, :class_name => 'OrderState', :foreign_key => 'previous_state'
end
