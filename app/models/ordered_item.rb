# -*- encoding : utf-8 -*-
class OrderedItem < ActiveRecord::Base
  belongs_to :item
  belongs_to :order
  has_many :products_log_warnings
  
  set_primary_key 'oid'
  
  
  def self.add_to_user(options)
    options.symbolize_keys!
    
    user = self.get_user(options[:user])
    
    item_id = options[:item_id].to_i
    amount = options[:amount].to_i
    
    item_ids = options[:item_ids]
    amounts = options[:amounts]
    
    deliver_at = Date.parse(options[:deliver_at].to_s)

    basket = user.basket
    
    if basket && basket.deliver_at.to_date < Date.today
      basket.destroy
      user.basket = basket = nil
    end
    
    unless(basket)
      basket = Order.create :user_id => user.id, :deliver_at => deliver_at, :state => "basket"
    end
    
    if item_ids && amounts
      rets = []
      for iid in item_ids
        rets << self.add_to_user(:user => options[:user], :item_id => iid, :amount => amounts[iid], :deliver_at => options[:deliver_at])
      end
      return rets
    elsif item_id && amount
      record = self.find :first, :conditions => "item_id = #{item_id} AND order_id = #{basket.id}"
      if record
        query = %{UPDATE ordered_items SET amount = #{amount + record.amount} WHERE item_id = #{item_id} AND order_id = #{basket.id}}
        self.connection.execute query
        return record
      else
        query = %{INSERT INTO ordered_items(item_id, order_id, amount) VALUES (#{item_id}, #{basket.id}, #{amount});}
        self.connection.execute query
        return (self.find_by_sql "SELECT * FROM ordered_items WHERE (item_id = #{item_id} AND order_id = #{basket.id}) LIMIT 1").first
      end
    end
  end
  
  protected
  
  def self.get_user(user)
    unless(user.is_a? User or user.is_a? UserSystem::Guest)
      if( (user_id = user.to_i) != 0)
        user = User.find(user_id)
      else
        raise ArgumentError
      end
    end
    
    return user
  end
end

