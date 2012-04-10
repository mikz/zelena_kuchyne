# -*- encoding : utf-8 -*-
class CreateMailAclRules < ActiveRecord::Migration
  def self.up
    sql_script 'mail_acl_rules_up'
  end

  def self.down
    sql_script 'mail_acl_rules_down'
  end
end

