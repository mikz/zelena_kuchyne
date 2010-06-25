class RestaurantSale < ActiveRecord::Base
  belongs_to :item
  belongs_to :premise
  belongs_to :buyer, :class_name => "User"
  
  validates_presence_of :item, :premise, :amount
  validates_numericality_of :amount
  after_create :create_ingredients_log
  after_update :update_ingredients_log
  
  def buyer_login= login
    self.buyer = User.find_by_login login
  end

  def buyer_login
    (self.buyer)? self.buyer.login : nil
  end
 
  def premise_name_abbr
    (premise)? premise.name_abbr : nil
  end
  
  def premise_name_abbr= name_abbr
    premise = Premise.find_by_name_abbr name_abbr
  end
  
  private
  def create_ingredients_log
    case self.item.item_type.to_sym
      when :meal
        meal = Meal.find_by_item_id(item_id, :include => {:recipes => :ingredient})
        IngredientsLogFromRestaurantEntry.create_for_meal( self, meal )
        if !meal.restaurant_flag
          scheduled_meal = ScheduledMeal.find(:first, :conditions => ["scheduled_for = ?::date AND meal_id = ?", self.sold_at, meal.id])
          if scheduled_meal && scheduled_meal.amount - self.amount > 0
            scheduled_meal.amount -= self.amount
            scheduled_meal.save!
          else
            amount = self.amount
            if scheduled_meal
              amount = (scheduled_meal.amount - self.amount).abs
              scheduled_meal.destroy
            end
            scheduled_menu = ScheduledMenu.find(:first, :include => {:menu => {:courses => :meal } }, :conditions => ["scheduled_for = ?::date AND meals.id = ?", self.sold_at, meal.id])
            if scheduled_menu
              scheduled_menu.set_amount_of_meal(meal, scheduled_menu.amount - amount)
            else
              raise ActiveRecord::RecordNotFound.new("ScheduledMenu or ScheduledMeal not found")
            end
          end
        end
      when :menu
        menu = Menu.find_by_item_id(item_id, :include => {:meals => {:recipes => :ingredient}})
        IngredientsLogFromRestaurantEntry.create_for_meals(self, menu.meals)
        scheduled_menu = ScheduledMenu.find(:first, :conditions => ["scheduled_for = ?::date AND menu_id = ?", self.sold_at, menu.id])
        scheduled_menu.amount -= self.amount
        scheduled_menu.save!
      when :bundle
        bundle = Bundle.find_by_item_id(item_id, :include => {:meal => {:recipes => :ingredient}})
        
        orig_amount = self.amount
        self.amount = self.amount * bundle.amount
        IngredientsLogFromRestaurantEntry.create_for_meal(self, bundle.meal )
        self.amount = orig_amount
        scheduled_bundle = ScheduledBundle.find(:first, :conditions => ["scheduled_for = ?::date AND bundle_id = ?", self.sold_at, bundle.id ])
        scheduled_bundle.amount -= self.amount
        scheduled_bundle.save!
      when :product
        throw NotImplementedException.new("restaurant can't sell products");
    end
  end
  
  def update_ingredients_log
    diff =  self.amount - self.amount_was
    case self.item.item_type.to_sym
      when :meal
        meal = Meal.find_by_item_id(item_id, :include => {:recipes => :ingredient})
        IngredientsLogFromRestaurantEntry.update_for_meal( self, meal )
        if !meal.restaurant_flag && diff > 0
          scheduled_meal = ScheduledMeal.find(:first, :conditions => ["scheduled_for = ?::date AND meal_id = ?", self.sold_at, meal.id])
          if scheduled_meal && scheduled_meal.amount - diff > 0
            scheduled_meal.amount -= diff
            scheduled_meal.save!
          else
            if scheduled_meal
              diff = (scheduled_meal.amount - diff).abs
              scheduled_meal.destroy
            end
            scheduled_menu = ScheduledMenu.find(:first, :include => {:menu => {:courses => :meal } }, :conditions => ["scheduled_for = ?::date AND meals.id = ?", self.sold_at, meal.id])
            if scheduled_menu
              scheduled_menu.set_amount_of_meal(meal, scheduled_menu.amount - diff)
            else
              raise ActiveRecord::RecordNotFound.new("ScheduledMenu or ScheduledMeal not found")
            end
          end
        end
      when :menu
        menu = Menu.find_by_item_id(item_id, :include => {:meals => {:recipes => :ingredient}})
        IngredientsLogFromRestaurantEntry.update_for_meals(self, menu.meals)
        if diff > 0
          scheduled_menu = ScheduledMenu.find(:first, :conditions => ["scheduled_for = ?::date AND menu_id = ?", self.sold_at, menu.id])
          scheduled_menu.amount -= diff
          scheduled_menu.save!
        end
      when :bundle
        bundle = Bundle.find_by_item_id(item_id, :include => {:meal => {:recipes => :ingredient}})
        self.amount = self.amount * bundle.amount
        IngredientsLogFromRestaurantEntry.create_for_meal(self, bundle.meal )
        self.amount = self.amount_was
        if diff > 0
          scheduled_bundle = ScheduledBundle.find(:first, :conditions => ["scheduled_for = ?::date AND bundle_id = ?", self.sold_at, bundle.id ])
          scheduled_bundle.amount -= diff
          scheduled_bundle.save!
        end
      when :product
        throw NotImplementedException.new("restaurant can't sell products");
    end
  end
    
end
