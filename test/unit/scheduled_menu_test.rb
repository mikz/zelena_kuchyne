# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/../test_helper'

class ScheduledMenuTest < ActiveSupport::TestCase
  def test_creating_ingredients_log_entries_bug
    scheduled_menu = ScheduledMenu.create( :menu => menus(:delikatni_menu), :amount => 100) {|sm| sm.scheduled_for = '2009-01-26'} # delikatni_menu has smetanova_polevka and pecene_brambory
    assert_valid scheduled_menu.reload
    ingredient = ingredients(:smetana)
    ingredients_log = IngredientsLogFromMenusEntry.find(:all, :conditions => ["scheduled_menu_id = ? AND ingredient_id = ?", scheduled_menu.oid, ingredient.id]) # smetanova_polevka and pecene_brambory are made from smetana
    assert_not_equal ingredients_log.first.amount, ingredients_log.last.amount # smetanova_polevka uses 100 units of smetana and pecene_brambory only 30 units
    scheduled_menu.amount += 100
    scheduled_menu.save # trigger wrongly updated ingredients log and set same value for ingredients from all menus
    ingredients_log = IngredientsLogFromMenusEntry.find(:all, :conditions => ["scheduled_menu_id = ? AND ingredient_id = ?", scheduled_menu.oid, ingredient.id])
    assert_not_equal ingredients_log.first.amount, ingredients_log.last.amount # if values are different, that bug is gone
  end
end

