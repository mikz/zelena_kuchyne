class Address < ActiveRecord::Base
  include MapyCz
  belongs_to :user
  belongs_to :zone
  validates_format_of :first_name, :family_name, :with =>  /^([^\+\*\!\\\/\=\@\#\$\~\^\&\{\}\°\[\]\;\<\>\_\(\)]*)$/, :message => "Špatný formát. "
  validates_presence_of :first_name, :if => :family_name?, :message => "Toto pole je povinné pokud vyplníte příjmení. "
  validates_presence_of :family_name, :if => :first_name?, :message => "Toto pole je povinné pokud vyplníte křestní jméno. "
  validates_presence_of :street, :house_no, :zip, :city, :message => "Toto pole je povinné. "
  validates_length_of :street, :house_no, :zip, :city, :minimum => 1, :message => "Toto pole je povinné. ",  :allow_nil => true
  validates_length_of :street, :city, :district, :maximum => 70, :too_long => "Maximální délka je %d znaků. ", :allow_nil => true
  validates_length_of :house_no, :maximum => 15, :too_long => "Maximální délka je %d znaků. ",  :allow_nil => true
  validates_length_of :first_name, :family_name, :company_name, :maximum => 100, :too_long => "Maximální délka je %d znaků. ", :allow_nil => true
  validates_format_of :zip, :with => /^((\d{3}\ {1}\d{2})|(\d{5}))$/, :if => :zip?, :message => "Špatný formát PSČ. "
  validates_length_of :zip, :maximum => 30, :too_long => "Maximální délka je %d znaků. ", :allow_nil => true
  validates_inclusion_of :address_type, :in => %w(delivery billing home)
  validates_presence_of :first_name, :unless => :name_or_company, :message => "Musíte vyplnit jméno a přijmení nebo název společnosti. "
  validates_presence_of :family_name, :unless => :name_or_company, :message => "Musíte vyplnit jméno a přijmení nebo název společnosti. "
  validates_presence_of :company_name , :unless => :name_or_company, :message => "Musíte vyplnit jméno a přijmení nebo název společnosti. "
  validates_length_of :note, :maximum => 100, :too_long => "Maximální délka je %d znaků. ", :allow_blank => true, :allow_nil => true
  validates_presence_of :zone_id, :message => %{Musíte vybrat zónu, kam vaše adresa patří dle <a href="/zony.html">mapy</a>.}
  after_save :check_orders_zone
  before_save proc{false }, :if => :disabled?
  attr_accessor :disabled
  
  PROTECTED_ATTRIBUTES = [:street, :house_no, :city, :district, :zip, :zone_id]
  
  def has_zone
    self.zone && !self.zone.hidden?
  end
  
  def validate
    errors.clear && return if disabled
    
    #validate_address if validate?
    
    PROTECTED_ATTRIBUTES.each do |attr|
      errors.add(attr, "Nelze změnit, když je adresa ověřena administrátorem.") if self.send("#{attr}_changed?")
    end if zone_reviewed? # && !UserSystem.current_user.belongs_to?("admins")
    
  end
  
  def fixme= val
    @fixme = val
  end
  
  def dont_validate= val
    @dont_validate = val
  end
  
  def disabled?
    !@disabled.blank?
  end
  
  
  def validate?
    return !(@dont_validate)
  end
  def fixme
    return @fixme || false
  end

  def output
    %{#{self.street} #{self.house_no} <br/>
      #{self.city}, #{self.district}}
  end
  
  def to_s
    %{#{self.street} #{self.house_no}, 
      #{self.city}, #{self.district}}
  end

  def method_missing(method, *args)
    attr = method.to_s
    if !(attr =~ /_changed\?$/) && (attr =~ /\?$/)
      return !(self.send attr.gsub("?","")).blank?
    else
      return super(method, *args)
    end
  end
  
  private
  
  def compare(str1, str2)
    return false if str1.blank? || str2.blank? 
    return (translit(str1.to_s).strip.downcase == translit(str2.to_s).strip.downcase)
  end
  
  def name_or_company
    return (first_name? && family_name?) || company_name?
  end
  def validate_address
    begin
      
      addresses = find_address :street => self.street, :house_no => self.house_no, :city => self.city
      address = addresses.first
      notes = []
      notes.push "Původní údaje - "
      if address && address.length == 3
        unless compare(self.street, address[:street])
          if fixme
            notes.push "ulice: #{self.street}"
            self.street = address[:street]
          else
            errors.add('street',"Ulice nenalezena. Nalezeno: #{address[:street]}. ")
          end
        end
        unless compare(address[:city], self.city)
          if fixme
            notes.push "město: #{self.city}"
            self.city = address[:city]
          else
            errors.add('city', "Město nenalezeno. Nalezeno: #{address[:city]}. ")
          end
        end
        errors.add('zip', 'Adresa neexistuje. ')
        errors.add('house_no', 'Adresa neexistuje. ')
        errors.add('district', 'Adresa neexistuje. ')
      elsif address && address.length == 6
        unless compare((self.zip.to_s||"").gsub(' ',''), address[:zip])
          if self.fixme
            self.zip = address[:zip]
          else
            errors.add('zip',"PSČ neodpovídá. Nalezeno: #{address[:zip]}. ")
          end
        end
        unless compare(address[:house_no].split("/").last, self.house_no) || compare(address[:house_no].split("/").first, self.house_no) || compare(address[:house_no], self.house_no)
          if fixme
            notes.push "číslo domu: #{self.house_no}"
            self.house_no = address[:house_no]
          else
            errors.add('house_no',"Číslo domu nenalezeno. Nalezeno: #{address[:house_no]}. ")
          end
        end
        unless compare(address[:district], self.district)
          if fixme
            self.district = address[:district]
          else
            errors.add('district', "Část obce nenalezena. Nalezeno: #{address[:district]}. ")
          end
        end
      end
      if notes.length > 1
          self.note = "#{self.note + " " if self.note}#{notes.delete_at(0)} #{notes.join(", ")}"
      end
      if addresses.length == 0
        errors.add('street', 'Adresa neexistuje. ')
        errors.add('city', 'Adresa neexistuje. ')
        errors.add('zip', 'Adresa neexistuje. ')
        errors.add('house_no', 'Adresa neexistuje. ')
        errors.add('district', 'Adresa neexistuje. ')
      end
      if errors.length > 0
        errors.add("dont_validate",'')
      end
    rescue Exception => e
      DEBUG {%w{e}}
      errors.add("dont_validate",'')
    end
    errors.clear if self.changed? and errors.size > 0 and self.fixme and address and address.length == 6
  end
  
  private
  def check_orders_zone
    return unless zone_reviewed_changed? && zone_reviewed? && !zone_reviewed_was
    orders = self.user.orders.find(:all, :conditions => ["state = ? AND delivery_methods.zone_id <> ? AND deliver_at::date >= current_date", 'order', zone_id], :include => [:delivery_method])
    orders.each do |order|
      order.update_delivery_method(true)
    end
  end
end
