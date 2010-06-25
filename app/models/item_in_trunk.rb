class ItemInTrunk < ActiveRecord::Base
  set_table_name "items_in_trunk"
  set_primary_key "oid"
  
  belongs_to :delivery_man
  belongs_to :item
  belongs_to :user, :foreign_key => "delivery_man_id", :class_name => "User"
  
  def self.update_items params
    query = ""
    params['ids'].each_pair do |key,val|
      query << "UPDATE items_in_trunk SET amount = '#{val['amount'].to_i}' WHERE item_id = '#{key.to_i}' AND delivery_man_id = '#{params['delivery_man_id'].to_i}' AND deliver_at = '#{Date.parse(params['scheduled_for']).to_s}';\n"
    end
    query << "DELETE FROM items_in_trunk WHERE amount <= 0;"
    self.connection.execute query
  end
  
  def self.update_amounts options={}
    query = ""
    options[:ids].each_pair do |key, val|
      query << "UPDATE items_in_trunk SET amount = (amount - #{val.to_i}) WHERE item_id = '#{key.to_i}' AND delivery_man_id = '#{options[:delivery_man_id].to_i}' AND deliver_at = '#{Date.parse(options[:deliver_at].to_s).to_s}';\n"
    end
    query << "DELETE FROM items_in_trunk WHERE amount <= 0;"
    self.connection.execute query
  end
end