module UsersHelper
  def translate_group group_name
    group_name = group_name.strip.gsub(" ","_")
    locales["group_#{group_name}".to_sym]
  end
  
  def translate_roles roles
    roles.split(",").map{|r| translate_group(r)}.join(", ")
  end
  
  def  address_output_with_zone_check user, address = nil
    address ||= user.delivery_address
    
    form = form_tag(:url => {:action => :set_zone, :id => user.id, :controller => :users}) do |f|
    end
    # do 
    #  content_tag(:select, ("<option/>" + @zones.collect{ |zone|  content_tag(:option, zone.name, :disabled => zone.hidden?)}.join),
    #    :name => "zone[zone_id]",
    #    :onchange => 'confirm("Opravdu chcete uživateli nastavit zónu?") && this.form.onsubmit();')
    #end) unless address.zone
    review = %{
      <br/>
      #{link_to_remote locales[:zone_reviewed].downcase,
          :url => {:controller => "users", :action => "set_zone", :id => user.id, :zone => {:zone_reviewed => true}}}
    } if address.zone && !address.zone_reviewed?
    %{
      <td class="#{'zone-error' unless address.zone and address.zone_reviewed?}">
        #{form || address.zone.name}
        #{review}
    }
  end
  def address_zone_cell user, address = nil
    address ||= user.delivery_address
    %{<td class="#{'zone-error' unless address.zone and address.zone_reviewed?}">#{address.output}</td>}
  end
end
