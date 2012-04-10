# -*- encoding : utf-8 -*-
module EshopHelper
  def seo_url(item)
    name = item.name
    name = ActiveSupport::Multibyte::Handlers::UTF8Handler.normalize(name,:d).split(//u).reject { |e| e.length > 1 }.join
    name.downcase!
    url = url_for :controller => :eshop, :action => :product, :id => item.id, :only_path => false
    name.gsub!(/[^\w]/," ")
    name.gsub!(/\s{1,}/,"_")
    url + "-" + name
  end
end

