# coding: utf-8

namespace :temporary_stuff do
  desc "fix products"
  task :fix_products => [:environment, 'mailer:init_fake_controller'] do
    @fc.current_user = User.find_by_login "mikz"
    ActiveRecord::Base.connection.execute %{
      UPDATE products SET disabled = true WHERE price = 0;
      UPDATE products SET term_of_delivery = '14 days' WHERE price > 0 AND cost > 0;
    }
  end
  
  desc "fix entities"
  task :fix_item_profiles => [:environment, 'mailer:init_fake_controller'] do
    @fc.current_user = User.find_by_login "mikz"
    fixes = [ 
      {:find => "&yacute;", :replace => "ý"},
      {:find => "&aacute;", :replace => "á"},
      {:find => "&scaron;", :replace => "š"},
      {:find => "&oacute;", :replace => "ó"},
      {:find => "&iacute;", :replace => "í"},
      {:find => "&eacute;", :replace => "é"},
      {:find => "&uacute;", :replace => "ú"},
      {:find => "&Uacute;", :replace => "Ú"},
      {:find => "&Scaron;", :replace => "Š"},
      {:find => "<p>&nbsp;", :replace => "<p>"},
      {:find => "&nbsp;</p>", :replace => "</p>"},
      {:find => "&nbsp;", :replace => " "},
      {:find => "  ", :replace => " "},
      {:find => "&deg;", :replace => "°"},
      {:find => "&ndash;", :replace => "–"},
      {:find => "&quot;", :replace => '"'},
      {:find => "&bdquo;", :replace => '"'},
      {:find => "&ldquo;", :replace => '"'}
    ]
    ActiveRecord::Base.connection.execute %{
      DELETE FROM item_profiles WHERE
      item_id NOT IN (SELECT item_id FROM items);
    }
    ItemProfile.find(:all).each { |i|
      fixes.each do |fix|
        i.field_body = i.field_body.gsub(fix[:find],fix[:replace])
      end
      i.save
    }
    Product.find(:all).each do |p|
      if p.short_description
        fixes.each do |fix|
          p.short_description = p.short_description.gsub(fix[:find],fix[:replace])
        end
      end
      p.save
    end
  end
  
  desc "gen report"
  task :gen_report => [:environment] do    
    since = Date.parse(ENV['SINCE'] || 1.year.ago.to_s)
    till = Date.parse(ENV['TILL'] || Date.today.to_s)
    column = ENV['COLUMN'] || "deliver_at"
    model = (ENV['MODEL'] || OrderView.to_s).constantize
    file = ENV['FILE'] || "report.xls"
    records =  model.find :all, :conditions => ["#{column} BETWEEN ? AND ? AND cancelled = false AND state <> ?", since, till, "basket"], :order => column, :include => [:user, :delivery_man, :delivery_method]
    File.open file, "w" do |file|
      file << records.to_xls(:methods => [:delivery_man_login, :user_login, :delivery_method_name], :only => [ :id, :deliver_at, :price, :delivery_price, :discount_price, :original_price, :notice, :state])
    end
    
  end
end
