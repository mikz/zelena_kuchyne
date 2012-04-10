# -*- encoding : utf-8 -*-
class AddOrderState < ActiveRecord::Migration
  def self.up
    execute %{
      INSERT INTO pg_enum(enumtypid, enumlabel) VALUES(
          (SELECT oid FROM pg_type WHERE typtype='e' AND typname='order_state'), 
          'validating'
      );
    }
  end

  def self.down
    
  end
end

