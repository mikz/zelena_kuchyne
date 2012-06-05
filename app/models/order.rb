# -*- encoding : utf-8 -*-
class Order < ActiveRecord::Base
  belongs_to :user
  belongs_to :delivery_man, :class_name => 'User', :foreign_key => 'delivery_man_id'
  has_many :ordered_items, :order => "items.name ASC", :include => [:item],  :foreign_key => 'order_id'
  has_many :items, :through => :ordered_items, :order => "items.name ASC"
  belongs_to :order_view, :foreign_key => 'id', :include => [:delivery_method]
  alias :view :order_view
  
  belongs_to :delivery_method, :foreign_key => "delivery_method_id"
  before_update Proc.new{|record| record.reload if(record[:state].nil?)}

  attr_accessor :original_state, :fixed_amounts
  before_validation Proc.new {|record| record.original_state = record.state_was if @original_state.nil?}
  after_save Proc.new {|record| record.update_delivery_method if !record.delivery_method_id_changed? && record.original_state == record.state }
  
  
  def merge other_order
    return false unless other_order.is_a?(self.class)
    return false if other_order.cancelled?
    oi_hash = self.ordered_items_hash
    error = false
    begin
      self.transaction do
        other_order.ordered_items_hash.each_pair do |item_id, other_oi|
          if oi_hash.has_key? item_id
            oi_hash[item_id].amount += other_oi.amount
          else
            self.ordered_items << OrderedItem.new(:item_id => item_id, :amount => other_oi.amount, :order => self)
          end
        end
        error ||= !other_order.toggle!(:cancelled)
        self.ordered_items.each do |oi|
          error ||= !oi.save!
        end
        error ||= !self.update_delivery_method(true)
        raise if error
      end
    rescue Exception => e
      STDERR << %{
        #{e.inspect}
      }
      error ||= true
    end
    !error
  end
  
  def cancel!
    self.update_attribute :cancelled, true
  end
  
  def validate
    return if self.user.guest
    validate_deliver_time if self.deliver_at.is_a?(Time)
    @stock = self.items_not_on_stock
    unless @stock.empty?
      ActiveRecord::Base.logger.debug("  Missing items:\t#{@stock.inspect}")
      self.errors.add "ordered_items", "are invalid"
    end
  end
  
  def time_of_delivery= val
    time = (val.is_a? String)? Time.parse(val) : val
    self.deliver_at = self.deliver_at.change :hour => time.hour, :min => time.min
  end
    
    
  def validate_deliver_time(time_now = Time.now)
    @delivery ||= Configuration.delivery
    
    deliver_at = Time.parse("#{self.deliver_at.hour}:#{self.deliver_at.min}")
    if @delivery[:from] > deliver_at || deliver_at > @delivery[:to]
      self.errors.add "deliver_at", "out_of_range"
    end
    self.errors.add("deliver_at", "too_soon") unless (self.deliver_at - time_now > 2*@delivery[:step]) # add error if delivery_at time is less than two delivery steps from
  end
  
    
  def self.delivery_times(order_time, time_now, user = nil)
    
    delivery = Configuration.delivery
    delivery[:steps] ||= []
    
    if user && user.limited_delivery_times?
      delivery.merge! user.delivery_times_limit
    end
    
    last = delivery[:to] - delivery[:last]

    if (Date.parse(order_time.to_s) == Date.parse(time_now.to_s) && time_now > last) || Date.parse(order_time.to_s) < Date.parse(time_now.to_s)
      delivery[:disabled] = true
      return delivery
    else
      delivery[:disabled] = false
    end

    if Date.parse(order_time.to_s) == Date.today
      time = time_now + 2*delivery[:step]
      delivery[:from] = Time.parse("#{time.hour}:#{(time.min/30).floor*30}")
      delivery[:from] += delivery[:step] if delivery[:from] < time
    end
    delivery_to = delivery[:to].clone
    while delivery_to >= delivery[:from] do
      delivery[:steps].push delivery_to
      delivery_to = delivery_to - delivery[:step]
    end
    delivery
  end
  
  def delivery_times(time_now = Time.now)
    self.class.delivery_times(self.deliver_at, time_now, self.user)
  end
  
  def ordered_items_recursive_ids
    meals = []
    menus = []
    bundles = []
    for ordered in ordered_items
      meals.push(ordered.item_id) if ordered.item.item_type == "meal"
      menus.push(ordered.item_id) if ordered.item.item_type == "menu"
      bundles.push(ordered.item_id) if ordered.item.item_type == "bundle"
    end
    if menus.length > 0
      self.connection.select_values(%{
        SELECT meals.item_id FROM menus
        LEFT JOIN courses ON menus.id = courses.menu_id
        LEFT JOIN meals ON courses.meal_id = meals.id
        WHERE menus.item_id IN (#{menus.join(", ")});
      }).each{|item_id| meals.push(item_id.to_i)}
    end
    if bundles.length > 0
      self.connection.select_values(%{
        SELECT meals.item_id FROM bundles
        LEFT JOIN meals ON meals.id = bundles.meal_id
        WHERE bundles.item_id IN (#{bundles.join(", ")});
      }).each{|item_id| meals.push(item_id.to_i)}
    end
    meals + menus + bundles
  end
    
  
  def self.days
    return self.connection.select_values("SELECT DISTINCT deliver_at FROM orders").collect {|date| Date.parse date }
  end
  
  def update_items(attr)
    query = String.new
    ordered_items = {}
    before_update = self.ordered_items.clone
    self.ordered_items.each do |oi|
      ordered_items[oi.item_id] = oi
    end
    deleted = []
    attr.each_pair do |key, value|
      id = value.to_i
      if id <= 0
        deleted.push(key.to_i)
        query += %{DELETE FROM ordered_items WHERE item_id = #{key.to_i} AND order_id = #{self.id};}
      else
        query += %{UPDATE ordered_items SET amount = #{id} WHERE item_id = #{key.to_i} AND order_id = #{self.id};}
      end
    end unless attr.nil?
    self.connection.execute query if query.length > 0
    self.ordered_items.reload
    unless self.eql_ordered_items?(before_update)
      update_delivery_method 
    end
    deleted
  end
  
  def update_or_insert_items(items)
    query = ""
    before_update = self.ordered_items.clone
    ordered_items = {}
    self.ordered_items.each do |oi|
      ordered_items[oi.item_id] = oi
    end
    items.each_pair do |key,value|
      amount = value.to_i
      if amount <= 0
        query += %{DELETE FROM ordered_items WHERE item_id = #{key.to_i} AND order_id = #{self.id};}
      else
        record = OrderedItem.find :first, :conditions => "item_id = #{key.to_i} AND order_id = #{self.id}"
        if record
          query += %{UPDATE ordered_items SET amount = #{amount} WHERE item_id = #{key.to_i} AND order_id = #{self.id};}
        else
          query += %{INSERT INTO ordered_items(item_id, order_id, amount) VALUES (#{key.to_i}, #{self.id}, #{amount});}
        end
      end
    end
    ret = self.connection.execute(query)
    self.ordered_items.reload
    unless self.eql_ordered_items?(before_update)
      update_delivery_method
    end
    return ret
  end

  def eql_ordered_items?(other_items)
    ordered_items = self.ordered_items_hash

    return false unless other_items.size == self.ordered_items.size

    other_items.each do |other_item|
      return false unless other_item == ordered_items[other_item.item_id]
      return false unless other_item.amount == ordered_items[other_item.item_id].amount
    end
    true
  end

  def ordered_menus
    menus = Menu.find_by_sql "SELECT menus.item_id AS menu_id, meals.item_id AS item_id FROM courses LEFT JOIN menus ON menus.id = courses.menu_id LEFT JOIN meals ON meals.id = courses.meal_id WHERE menus.item_id IN (#{self.item_ids.join(',')})"
    for menu in menus
      menu.menu_id = menu.menu_id.to_i
      menu.item_id = menu.item_id.to_i
    end
    @menus = {}
    menus.each do |e|
      @menus[e.item_id] = (@menus[e.item_id].nil?)? [e] : @menus[e.item_id].push(e)
    end
    return @menus
  end
  
  def set_delivery_man_id id
    if id == 0 || id.blank?
      return self.delivery_man_id = nil
    else
      self.delivery_man_id = id
    end
    
    ids = {}
    items_in_trunk = {}
    ItemInTrunk.find(:all, :conditions => ["deliver_at = ?::date AND delivery_man_id = ?", self.deliver_at, id]).each do |iit|
      items_in_trunk[iit.item_id] = iit
    end
    
    for oi in self.ordered_items
      if oi.item.menu?
        max_amount = nil
        meal_item_ids = []
        meals = Meal.find(:all, :include => [:menus], :conditions => ["menus.item_id = ?",oi.item_id])
        meals.each do |meal|
          if items_in_trunk[meal.item_id].nil?
            max_amount = nil
            break
          end
          max_amount = (max_amount.nil? || items_in_trunk[meal.item_id].amount < max_amount)? items_in_trunk[meal.item_id].amount : max_amount
          meal_item_ids << meal.item_id
        end
        break unless max_amount.to_i > 0
        amount = (max_amount < oi.amount)? max_amount : oi.amount
        meal_item_ids.each do |item_id|
          next if items_in_trunk[item_id].amount <= 0
          items_in_trunk[item_id].amount -= amount
          ids[item_id] ||= 0
          ids[item_id] += amount
        end
      else
        ids[oi.item_id] ||= 0
        ids[oi.item_id] += (items_in_trunk[oi.item_id] && items_in_trunk[oi.item_id].amount < oi.amount)? items_in_trunk[oi.item_id].amount : oi.amount
      end
    end
    
    ItemInTrunk.update_amounts :ids => ids, :delivery_man_id => id, :deliver_at => self.deliver_at
  end
  
  def ordered_items_stock_levels
    stock_levels = Stock.find :all, :conditions => ["scheduled_for = ?", Date.parse(deliver_at.to_s)]
    @ordered_items_stock_levels = {}
    stock_levels.each { |stock|
      @ordered_items_stock_levels[stock.item_id] = stock
    }
    @ordered_items_stock_levels
  end
  
  def items_not_on_stock
    deliver_at = Date.parse(self[:deliver_at].to_s)
    s = self.state

    self.state = "order"
    self.save_without_validation
    ordered_ids = ordered_items_recursive_ids
    missing = Stock.find_by_sql %{
      SELECT item_id,amount_left
      FROM scheduled_meals_left_view
      WHERE scheduled_for = '#{deliver_at.to_s}'
      AND amount_left < 0
      #{"AND item_id IN (#{ordered_ids.join(", ")})" unless ordered_ids.empty?}
    }
    self.state = s
    self.state_will_change!
    self.save_without_validation

    @missing = {}
    missing.each do |e|
      @missing[e.item_id] = e
    end
    @missing
  end
  
  def ordered_items_hash
    ordered = {}
    self.ordered_items.each do |e|
      ordered[e.item_id] = e
    end
    ordered
  end
  
  def fix_amounts missing = {}
    missing = @stock if missing.empty?
    ordered = self.ordered_items_hash
    sql = {}
    menus_buff = {}
    ordered_items_buff = {}
    missing.each_pair { |item_id, missing_item|
      if ordered[item_id]
        sql[item_id] = ordered[item_id].amount + missing_item.amount_left
        if (sql[item_id] < 0)
          missing[item_id].amount_left -= missing_item.amount_left + sql[item_id]*-1
          sql[item_id] = 0
        else
          missing[item_id].amount_left -= missing_item.amount_left
        end
      end
    }
    #count highest possible menu amount
    ordered.each_pair { |ordered_item_id, ordered_item|
      case ordered_item.item.item_type 
        when "menu"
          menu = Menu.find_by_item_id ordered_item.item_id, :include => [:meals]
          menus_buff[menu.item_id] = menu
          shit = []
          menu.meals.each { |meal|
            if missing[meal.item_id] and missing[meal.item_id].amount_left < 0
              meal_ordered_amount = ((ordered[meal.item_id]) ? ordered[meal.item_id].amount : 0)
              new_amount = ordered_item.amount + missing[meal.item_id].amount_left
              err = {:menu_amount => ordered_item.amount, :new_menu_amount => new_amount, :meal_missing_amount => missing[meal.item_id].amount_left, :meal_ordered_amount => meal_ordered_amount, :item => meal.name}
              shit.push err
              sql[menu.item_id] = new_amount if (sql[menu.item_id].nil? or new_amount < sql[menu.item_id])
            end
          }
        when "bundle"
          bundle = Bundle.find_by_item_id ordered_item.item_id, :include => [:meal]
          meal_ordered_amount = ((ordered[bundle.meal.item_id]) ? ordered[bundle.meal.item_id].amount : 0)
          new_amount = (ordered_item.amount*bundle.amount + missing[bundle.meal.item_id].amount_left)/bundle.amount
          sql[bundle.item_id] = new_amount if (sql[bundle.item_id].nil? or new_amount < sql[bundle.item_id])
      end
      ordered_items_buff[ordered_item.item_id] = ordered_item
    }
    
    stock_levels = ordered_items_stock_levels
    # deconstruct menu and add its meals
    sql.dup.each_pair {|item_id, new_amount|
      ordered_item = ordered_items_buff[item_id] || ordered[item_id]
      if ordered_item
        if ordered_item.amount > new_amount
          if ordered_item.item.item_type == "menu"
            menu = menus_buff[ordered_item.item_id]
            menu.meals.each {|meal|
              meal_missing_amount = ((missing[meal.item_id]) ? missing[meal.item_id].amount_left : 0)
              meal_ordered_amount = ((ordered[meal.item_id]) ? ordered[meal.item_id].amount : 0)
              if meal_missing_amount < 0
                amount = amount = ordered_item.amount - new_amount + meal_missing_amount
              else
                amount = ordered_item.amount - new_amount + meal_missing_amount + meal_ordered_amount
              end
              err = {:menu_amount => ordered_item.amount, :new_menu_amount => new_amount, :meal_missing_amount => meal_missing_amount, :meal_ordered_amount => meal_ordered_amount, :item => meal.name, :amount => amount}
              sql[meal.item_id] = (amount + new_amount > stock_levels[meal.item_id].amount_left) ? stock_levels[meal.item_id].amount_left - new_amount : amount
            }
          end
        end
      end
    }
    
    sql = sql.delete_if { |item_id,amount|
      ordered[item_id].nil? and amount == 0
    }
    self.update_or_insert_items sql
    self.make_menus_from_meals :items_cache => ordered_items_buff, :menus_cache => menus_buff
    @fixed_amounts = true
  end
  
  def fixed_amounts?
    @fixed_amounts.present?
  end
  
  def make_menus_from_meals options = {}
    @today_menus = ScheduledMenu.find :all, :conditions => ["scheduled_for = ?", Date.parse(deliver_at.to_s)], :include => [{:menu => :meals}]
    self.ordered_items.reload
    ordered = ordered_items_hash
    items_cache = options[:items_cache] || {}
    menus_cache = options[:menus_cache] || {}
    sql = {}

    ordered.each_pair { |ordered_item_id, ordered_item|
      ordered_item = items_cache[ordered_item_id] || ordered[ordered_item_id]
      if ordered_item.item.item_type == "menu"
        menu = menus_cache[ordered_item_id] || Menu.find_by_item_id(ordered_item.item_id, :include => [:meals])
        menus_cache[ordered_item_id] = menu
        have_meals = true
        value = nil
        menu.meal_ids.each { |meal_id|
          have_meals = false if ordered[meal_id].nil?
          if have_meals
            value = ordered[meal_id].amount if value.nil? or value > ordered[meal_id].amount
          end
        }
        if have_meals
          menu.meal_ids.each { |meal_id|
            sql[meal_id] = (ordered[meal_id].amount -= value)
          }
          sql[ordered_item_id] = (ordered[ordered_item_id].amount += value)
        end
      end
    }
    @today_menus.each { |scheduled_menu|
      valid = true
      value = nil
      meal_ids = scheduled_menu.menu.meal_ids
      menu_item_id = scheduled_menu.menu.item_id
      meal_ids.each { |meal_id|
        if ordered.keys.include? meal_id
          value = ordered[meal_id].amount if value.nil? or value > ordered[meal_id].amount
        else
          valid = false
        end
      }
      if valid
        meal_ids.each { |meal_id|
          sql[meal_id] = (ordered[meal_id].amount -= value)
        }
        if ordered[menu_item_id]
          sql[menu_item_id] = (ordered[menu_item_id].amount += value)
        else
          sql[menu_item_id] = value
        end
      end
    }
    self.update_or_insert_items sql
  end
  
  alias_method :valid_with_callbacks?, :valid?
  def valid?
    self.send(:valid_without_callbacks?)
  end
  
  
  def update_delivery_method(save = false)
    unless self.new_record? || @updating_delivery_method || self.ordered_item_ids.size == 0
      method = DeliveryMethod.find_by_id self.user.preferred_delivery_method_id.to_i if self.user && !self.user.preferred_delivery_method_id.blank?
      method ||= self.order_view.reload.possible_delivery_methods.first

      self.delivery_method_id = (method)? method.id : nil
      self.delivery_method_id_will_change!
      unless self.delivery_method_id_was == self.delivery_method_id
        @updating_delivery_method = true
        self.send(:update_without_callbacks)
        @updating_delivery_method = false
        self.order_view.reload
      end
    end
    self.save_without_validation if save
  end
  
  def disabled?
    self.delivery_times[:disabled] || self.delivery_method.nil?
  end
  
  def delivery_method_with_autoload
    if delivery_method_without_autoload.nil?
      update_delivery_method
      return delivery_method_without_autoload
    else
      return delivery_method_without_autoload
    end
  end
  alias_method_chain :delivery_method, :autoload
end

