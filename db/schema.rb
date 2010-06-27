# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100626212118) do

  create_table "addresses", :force => true do |t|
    t.integer "user_id",                                          :null => false
    t.string  "address_type",  :limit => 8,   :default => "home", :null => false
    t.string  "country_code",  :limit => 3,   :default => "CZE",  :null => false
    t.string  "city",          :limit => 70,                      :null => false
    t.string  "house_no",      :limit => 15,                      :null => false
    t.string  "district",      :limit => 70,                      :null => false
    t.string  "street",        :limit => 70,                      :null => false
    t.string  "zip",           :limit => 30,                      :null => false
    t.string  "note",          :limit => 100
    t.string  "first_name",    :limit => 100
    t.string  "family_name",   :limit => 100
    t.string  "company_name",  :limit => 100
    t.integer "zone_id"
    t.boolean "zone_reviewed",                :default => false
  end

  add_index "addresses", ["id"], :name => "addresses_id_key", :unique => true

# Could not dump table "bundles" because of following StandardError
#   Unknown type 'item_type' for column 'item_type'

  create_table "cars", :force => true do |t|
    t.string "registration_no",  :limit => 10,                 :null => false
    t.float  "fuel_consumption",                               :null => false
    t.string "note",             :limit => 50, :default => "", :null => false
  end

  create_table "cars_logbooks", :force => true do |t|
    t.integer  "car_id",                             :null => false
    t.integer  "user_id",                            :null => false
    t.date     "date",                               :null => false
    t.integer  "beginning",                          :null => false
    t.integer  "ending",                             :null => false
    t.integer  "business_distance",   :default => 0, :null => false
    t.integer  "private_distance",    :default => 0, :null => false
    t.integer  "logbook_category_id"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.integer  "updated_by"
  end

  create_table "categorized_products", :id => false, :force => true do |t|
    t.integer "oid",                 :null => false
    t.integer "product_id",          :null => false
    t.integer "product_category_id", :null => false
  end

  add_index "categorized_products", ["oid"], :name => "categorized_products_oid_key", :unique => true

  create_table "configuration", :id => false, :force => true do |t|
    t.string "key",   :limit => 20, :null => false
    t.string "value", :limit => 50
  end

  create_table "country_codes", :force => true do |t|
    t.string  "name", :limit => 70, :null => false
    t.integer "code",               :null => false
  end

  add_index "country_codes", ["name"], :name => "country_codes_name_key", :unique => true

  create_table "courses", :force => true do |t|
    t.integer "meal_id", :null => false
    t.integer "menu_id", :null => false
  end

  add_index "courses", ["id"], :name => "courses_id_key", :unique => true

  create_table "delivery_methods", :force => true do |t|
    t.string  "name",                  :limit => 70,                    :null => false
    t.string  "basket_name",           :limit => 70, :default => "",    :null => false
    t.float   "price",                                                  :null => false
    t.float   "minimal_order_price",                                    :null => false
    t.boolean "flag_has_delivery_man",               :default => false, :null => false
    t.integer "zone_id",                                                :null => false
  end

  add_index "delivery_methods", ["name"], :name => "delivery_methods_name_key", :unique => true

  create_table "dialy_menu_entries", :force => true do |t|
    t.integer "dialy_menu_id", :null => false
    t.integer "category_id",   :null => false
    t.string  "name",          :null => false
    t.decimal "price",         :null => false
  end

  create_table "dialy_menu_scheduled", :force => true do |t|
    t.integer "dialy_menu_id",                   :null => false
    t.integer "item_id",                         :null => false
    t.boolean "disabled",      :default => true, :null => false
  end

  create_table "dialy_menu_scheduleds", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dialy_menus", :force => true do |t|
    t.date "date", :null => false
  end

  add_index "dialy_menus", ["date"], :name => "dialy_menus_date_key", :unique => true

  create_table "expense_categories", :force => true do |t|
    t.string "name",        :limit => 70,                  :null => false
    t.string "description", :limit => 105, :default => "", :null => false
  end

  add_index "expense_categories", ["id"], :name => "expense_categories_id_key", :unique => true

# Could not dump table "expenses" because of following StandardError
#   Unknown type 'expense_owner' for column 'expense_owner'

  create_table "flagged_meals", :id => false, :force => true do |t|
    t.integer "oid",          :null => false
    t.integer "meal_id",      :null => false
    t.integer "meal_flag_id", :null => false
  end

  add_index "flagged_meals", ["oid"], :name => "flagged_meals_oid_key", :unique => true

  create_table "fuel", :force => true do |t|
    t.integer  "user_id",                                   :null => false
    t.integer  "car_id",                                    :null => false
    t.float    "cost",                                      :null => false
    t.float    "amount",                                    :null => false
    t.string   "note",       :limit => 100, :default => "", :null => false
    t.datetime "date",                                      :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "updated_by"
  end

  create_table "groups", :force => true do |t|
    t.string  "title",         :limit => 50,                    :null => false
    t.boolean "default_group",               :default => false, :null => false
    t.string  "system_name",   :limit => 50
  end

  create_table "ingredient_consumptions", :force => true do |t|
    t.integer "ingredient_id",  :null => false
    t.integer "stocktaking_id", :null => false
    t.float   "consumption",    :null => false
  end

  create_table "ingredients", :force => true do |t|
    t.integer "supplier_id"
    t.string  "unit",        :limit => 25,                    :null => false
    t.string  "name",        :limit => 50,                    :null => false
    t.string  "code",        :limit => 50, :default => "",    :null => false
    t.boolean "supply_flag",               :default => false, :null => false
    t.float   "cost",                                         :null => false
  end

  add_index "ingredients", ["id"], :name => "ingredients_id_key", :unique => true

# Could not dump table "ingredients_log" because of following StandardError
#   Unknown type 'ingredients_log_entry_owner' for column 'entry_owner'

  create_table "ingredients_log_from_meals", :force => true do |t|
    t.date    "day",               :null => false
    t.float   "amount",            :null => false
    t.integer "ingredient_id",     :null => false
    t.float   "ingredient_price",  :null => false
    t.integer "meal_id",           :null => false
    t.integer "scheduled_meal_id", :null => false
    t.integer "consumption_id"
  end

  create_table "ingredients_log_from_menus", :force => true do |t|
    t.date    "day",               :null => false
    t.float   "amount",            :null => false
    t.integer "ingredient_id",     :null => false
    t.float   "ingredient_price",  :null => false
    t.integer "meal_id",           :null => false
    t.integer "scheduled_menu_id", :null => false
    t.integer "consumption_id"
  end

  create_table "ingredients_log_from_restaurant", :force => true do |t|
    t.date    "day",                :null => false
    t.float   "amount",             :null => false
    t.integer "ingredient_id",      :null => false
    t.float   "ingredient_price",   :null => false
    t.integer "meal_id",            :null => false
    t.integer "restaurant_sale_id", :null => false
    t.integer "consumption_id"
  end

  create_table "ingredients_log_from_stocktakings", :force => true do |t|
    t.date    "day",            :null => false
    t.float   "amount",         :null => false
    t.integer "ingredient_id",  :null => false
    t.integer "stocktaking_id", :null => false
  end

  create_table "ingredients_log_watchdogs", :force => true do |t|
    t.integer  "ingredient_id",              :null => false
    t.string   "operator",      :limit => 3, :null => false
    t.float    "value",                      :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  create_table "item_discounts", :force => true do |t|
    t.integer  "item_id",                                  :null => false
    t.float    "amount",                  :default => 0.0, :null => false
    t.string   "name",      :limit => 50,                  :null => false
    t.datetime "start_at",                                 :null => false
    t.datetime "expire_at",                                :null => false
    t.string   "note",      :limit => 50
  end

  create_table "item_profile_types", :force => true do |t|
    t.string  "name",      :limit => 50,                    :null => false
    t.string  "data_type", :limit => 50,                    :null => false
    t.boolean "visible",                 :default => true,  :null => false
    t.boolean "editable",                :default => true,  :null => false
    t.boolean "required",                :default => false, :null => false
  end

  add_index "item_profile_types", ["name"], :name => "item_profile_types_name_key", :unique => true

  create_table "item_profiles", :force => true do |t|
    t.integer  "item_id",    :null => false
    t.integer  "field_type", :null => false
    t.text     "field_body"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

# Could not dump table "items" because of following StandardError
#   Unknown type 'item_type' for column 'item_type'

  create_table "items_in_trunk", :id => false, :force => true do |t|
    t.integer "oid",                            :null => false
    t.integer "item_id",                        :null => false
    t.integer "delivery_man_id",                :null => false
    t.integer "amount",          :default => 0, :null => false
    t.date    "deliver_at",                     :null => false
  end

  add_index "items_in_trunk", ["oid"], :name => "items_in_trunk_oid_key", :unique => true

  create_table "logbook_categories", :force => true do |t|
    t.string "name", :limit => 50, :null => false
  end

  create_table "lost_items", :id => false, :force => true do |t|
    t.integer  "oid",                    :null => false
    t.integer  "item_id",                :null => false
    t.integer  "user_id",                :null => false
    t.integer  "amount",  :default => 0, :null => false
    t.float    "cost",                   :null => false
    t.datetime "lost_at",                :null => false
  end

  add_index "lost_items", ["oid"], :name => "lost_items_oid_key", :unique => true

  create_table "mail_acl_rules", :id => false, :force => true do |t|
    t.integer "rule_id",                  :null => false
    t.integer "mailbox_id",               :null => false
    t.integer "group_id",                 :null => false
    t.string  "action",     :limit => 15, :null => false
  end

  add_index "mail_acl_rules", ["rule_id"], :name => "mail_acl_rules_rule_id_key", :unique => true

  create_table "mail_conversations", :id => false, :force => true do |t|
    t.integer "conversation_id",                                  :null => false
    t.integer "mailbox_id",                                       :null => false
    t.integer "handled_by"
    t.string  "tracker",         :limit => 10,                    :null => false
    t.text    "note"
    t.boolean "flag_closed",                   :default => false, :null => false
  end

  add_index "mail_conversations", ["conversation_id"], :name => "mail_conversations_conversation_id_key", :unique => true

  create_table "mail_mailboxes", :primary_key => "mailbox_id", :force => true do |t|
    t.string "address",       :limit => 100, :null => false
    t.string "from_name"
    t.string "human_name",    :limit => 100
    t.text   "description"
    t.string "imap_server",   :limit => 100, :null => false
    t.string "imap_login",    :limit => 100, :null => false
    t.string "imap_password", :limit => 100, :null => false
  end

  add_index "mail_mailboxes", ["address"], :name => "mail_mailboxes_address_key", :unique => true

# Could not dump table "mail_messages" because of following StandardError
#   Unknown type 'message_direction' for column 'direction'

  create_table "meal_categories", :force => true do |t|
    t.string "name", :limit => 70, :null => false
  end

  add_index "meal_categories", ["id"], :name => "meal_categories_id_key", :unique => true

  create_table "meal_category_order", :id => false, :force => true do |t|
    t.integer "category_id", :null => false
    t.integer "order_id",    :null => false
  end

  create_table "meal_flags", :force => true do |t|
    t.string "name",        :limit => 30, :null => false
    t.string "description"
    t.string "icon_path"
  end

  add_index "meal_flags", ["name"], :name => "meal_flags_name_key", :unique => true

# Could not dump table "meals" because of following StandardError
#   Unknown type 'item_type' for column 'item_type'

  create_table "memberships", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "group_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "memberships", ["id"], :name => "memberships_id_key", :unique => true

# Could not dump table "menus" because of following StandardError
#   Unknown type 'item_type' for column 'item_type'

  create_table "news", :force => true do |t|
    t.string   "title",      :limit => 80, :null => false
    t.text     "body"
    t.datetime "publish_at",               :null => false
    t.datetime "expire_at"
  end

  create_table "ordered_items", :id => false, :force => true do |t|
    t.integer "oid",      :null => false
    t.integer "item_id",  :null => false
    t.integer "order_id", :null => false
    t.integer "amount",   :null => false
    t.float   "price",    :null => false
  end

  add_index "ordered_items", ["oid"], :name => "ordered_items_oid_key", :unique => true

# Could not dump table "orders" because of following StandardError
#   Unknown type 'order_state' for column 'state'

  create_table "page_histories", :force => true do |t|
    t.integer "page_id",               :null => false
    t.string  "url",     :limit => 50, :null => false
  end

  add_index "page_histories", ["id"], :name => "page_histories_id_key", :unique => true

  create_table "pages", :force => true do |t|
    t.string   "title",      :limit => 80,                   :null => false
    t.text     "body"
    t.string   "url",        :limit => 50,                   :null => false
    t.boolean  "editable",                 :default => true, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pages", ["id"], :name => "pages_id_key", :unique => true

  create_table "poll_answers", :force => true do |t|
    t.integer "poll_id",                :null => false
    t.string  "text",    :limit => 100, :null => false
  end

  create_table "poll_votes", :force => true do |t|
    t.integer "user_id"
    t.integer "poll_answer_id", :null => false
  end

# Could not dump table "polls" because of following StandardError
#   Unknown type 'poll_type' for column 'poll_type'

  create_table "premises", :force => true do |t|
    t.string "name",        :limit => 100, :null => false
    t.string "name_abbr",   :limit => 20,  :null => false
    t.text   "address"
    t.text   "description"
  end

  add_index "premises", ["name_abbr"], :name => "premises_name_abbr_key", :unique => true

  create_table "product_categories", :force => true do |t|
    t.integer "parent_id"
    t.integer "lft"
    t.integer "rgt"
    t.string  "name",        :limit => 50, :null => false
    t.text    "description"
  end

# Could not dump table "products" because of following StandardError
#   Unknown type 'item_type' for column 'item_type'

  create_table "products_log", :force => true do |t|
    t.date     "day",                                         :null => false
    t.integer  "product_id",                                  :null => false
    t.integer  "amount",                                      :null => false
    t.float    "product_cost",                                :null => false
    t.string   "note",         :limit => 200, :default => "", :null => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.integer  "updated_by"
  end

  create_table "products_log_warnings", :force => true do |t|
    t.integer  "ordered_item_id"
    t.datetime "created_at",      :null => false
  end

  add_index "products_log_warnings", ["ordered_item_id"], :name => "products_log_warnings_ordered_item_id_key", :unique => true

  create_table "recipes", :force => true do |t|
    t.float   "amount",        :null => false
    t.integer "ingredient_id", :null => false
    t.integer "meal_id",       :null => false
  end

  add_index "recipes", ["id"], :name => "recipes_id_key", :unique => true

  create_table "restaurant_sales", :force => true do |t|
    t.integer  "item_id",                   :null => false
    t.integer  "premise_id",                :null => false
    t.integer  "amount",                    :null => false
    t.float    "price",                     :null => false
    t.integer  "buyer_id"
    t.string   "note",       :limit => 100
    t.datetime "sold_at",                   :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "scheduled_bundles", :id => false, :force => true do |t|
    t.integer "oid",                              :null => false
    t.integer "bundle_id",                        :null => false
    t.date    "scheduled_for",                    :null => false
    t.boolean "invisible",     :default => false, :null => false
  end

  add_index "scheduled_bundles", ["oid"], :name => "scheduled_bundles_oid_key", :unique => true

  create_table "scheduled_meals", :id => false, :force => true do |t|
    t.integer  "oid",                              :null => false
    t.integer  "meal_id",                          :null => false
    t.date     "scheduled_for",                    :null => false
    t.integer  "amount",                           :null => false
    t.boolean  "invisible",     :default => false, :null => false
    t.datetime "created_at",                       :null => false
  end

  add_index "scheduled_meals", ["oid"], :name => "scheduled_meals_oid_key", :unique => true

  create_table "scheduled_menus", :id => false, :force => true do |t|
    t.integer  "oid",                              :null => false
    t.integer  "menu_id",                          :null => false
    t.date     "scheduled_for",                    :null => false
    t.integer  "amount",                           :null => false
    t.boolean  "invisible",     :default => false, :null => false
    t.datetime "created_at",                       :null => false
  end

  add_index "scheduled_menus", ["oid"], :name => "scheduled_menus_oid_key", :unique => true

  create_table "snippets", :id => false, :force => true do |t|
    t.string  "name",          :limit => 50,                   :null => false
    t.text    "content"
    t.boolean "cachable_flag",               :default => true, :null => false
  end

  create_table "sold_items", :primary_key => "oid", :force => true do |t|
    t.integer  "item_id", :null => false
    t.integer  "user_id", :null => false
    t.integer  "amount",  :null => false
    t.float    "price",   :null => false
    t.datetime "sold_at", :null => false
  end

  create_table "spices", :force => true do |t|
    t.integer "supplier_id"
    t.string  "name",        :limit => 50, :null => false
  end

  add_index "spices", ["name"], :name => "spices_name_key", :unique => true

  create_table "stocktakings", :force => true do |t|
    t.date "date"
  end

  add_index "stocktakings", ["date"], :name => "stocktakings_date_key", :unique => true

  create_table "suppliers", :force => true do |t|
    t.string "name",      :limit => 70, :null => false
    t.string "name_abbr", :limit => 10, :null => false
    t.text   "address"
  end

  add_index "suppliers", ["id"], :name => "suppliers_id_key", :unique => true
  add_index "suppliers", ["name_abbr"], :name => "suppliers_name_abbr_key", :unique => true

  create_table "used_spices", :force => true do |t|
    t.integer "spice_id", :null => false
    t.integer "meal_id",  :null => false
  end

  add_index "used_spices", ["id"], :name => "used_spices_id_key", :unique => true

# Could not dump table "user_discounts" because of following StandardError
#   Unknown type 'discount_class' for column 'discount_class'

  create_table "user_import", :id => false, :force => true do |t|
    t.integer  "iduziv",                                            :null => false
    t.string   "loginname",       :limit => 50,                     :null => false
    t.string   "passwdmd5",       :limit => 150,                    :null => false
    t.string   "passwduziv",      :limit => 150,                    :null => false
    t.string   "jmeno",           :limit => 100,                    :null => false
    t.string   "prijmeni",        :limit => 100,                    :null => false
    t.string   "email",           :limit => 200,                    :null => false
    t.string   "telefon",         :limit => 12,                     :null => false
    t.string   "adresa",          :limit => 200,                    :null => false
    t.string   "mesto",           :limit => 100,                    :null => false
    t.string   "psc",             :limit => 7,                      :null => false
    t.integer  "dodani",                                            :null => false
    t.string   "jmenodod",        :limit => 100,                    :null => false
    t.string   "prijmenidod",     :limit => 100,                    :null => false
    t.string   "adresadod",       :limit => 200,                    :null => false
    t.string   "mestodod",        :limit => 100,                    :null => false
    t.string   "pscdod",          :limit => 7,                      :null => false
    t.string   "firma",                                             :null => false
    t.string   "ico",             :limit => 25,                     :null => false
    t.string   "dic",             :limit => 25,                     :null => false
    t.integer  "objednavek",                                        :null => false
    t.integer  "cena_objednavek",                                   :null => false
    t.integer  "sleva",                                             :null => false
    t.datetime "last_order"
    t.boolean  "skip",                           :default => false, :null => false
    t.boolean  "updated",                        :default => false, :null => false
    t.integer  "user_id"
  end

  create_table "user_profile_types", :force => true do |t|
    t.string  "name",      :limit => 50,                     :null => false
    t.string  "data_type", :limit => 100,                    :null => false
    t.boolean "visible",                  :default => true,  :null => false
    t.boolean "editable",                 :default => true,  :null => false
    t.boolean "required",                 :default => false, :null => false
  end

  add_index "user_profile_types", ["name"], :name => "user_profile_types_name_key", :unique => true

  create_table "user_profiles", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "field_type", :null => false
    t.text     "field_body"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "user_profiles", ["id"], :name => "user_profiles_id_key", :unique => true

  create_table "user_tokens", :force => true do |t|
    t.integer  "user_id",                  :null => false
    t.string   "token",      :limit => 32, :null => false
    t.datetime "created_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                 :limit => 50
    t.string   "password_hash"
    t.string   "salt"
    t.boolean  "guest",                               :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                 :limit => 50
    t.float    "imported_orders_price",               :default => 0.0,   :null => false
  end

  add_index "users", ["login"], :name => "users_login_key", :unique => true

  create_table "wholesale_discounts", :force => true do |t|
    t.integer  "user_id",                                       :null => false
    t.float    "discount_price",                                :null => false
    t.string   "note",           :limit => 150, :default => "", :null => false
    t.datetime "start_at",                                      :null => false
    t.datetime "expire_at"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "updated_by"
  end

  create_table "zones", :force => true do |t|
    t.string  "name",     :limit => 70,                    :null => false
    t.boolean "disabled",               :default => false, :null => false
    t.boolean "hidden",                 :default => false, :null => false
  end

  add_index "zones", ["name"], :name => "zones_name_key", :unique => true

end
