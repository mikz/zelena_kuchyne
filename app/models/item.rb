class Item < ActiveRecord::Base
  has_many :item_profiles, :finder_sql => 'SELECT * FROM item_profiles WHERE item_id = #{item_id}' # FIXME: this association will fail while loaded by :include
  has_many :ordered_items, :finder_sql => 'SELECT * FROM ordered_items WHERE item_id = #{item_id}' # FIXME: this association will fail while loaded by :include
  has_many :orders, :through => :ordered_items
  belongs_to :last_update_by, :class_name => 'User', :foreign_key => 'updated_by'
  has_many :item_discounts, :finder_sql => 'SELECT * FROM item_discounts WHERE item_id = #{item_id}' # FIXME: this association will fail while loaded by :include
  before_create :ignore_item_id
  before_create :ignore_item_type
  after_create :unignore_item_id
  after_create :unignore_item_type

  after_save :update_profiles
  before_save :set_updated_by

  attr_readonly :item_id

  # Active record attempts to save a NULL into item_id on create, which we don't want.
  def attributes_with_quotes(include_primary_key = true, include_readonly_attributes = true, attribute_names = self.attributes.keys)
    if @ignore_item_id
       attribute_names.delete("item_id")
    end
    if @ignore_item_type
      attribute_names.delete("item_type")
    end
    super(include_primary_key,include_readonly_attributes,attribute_names)
  end

  # if the record has just been saved it doesn't know its item_id so we may need to look it up
  def item_id
    return nil if new_record?
    return @item_id if @item_id
    @item_id = super()
    if(@item_id)
      return @item_id
    else
      table_name = self.class.to_s.demodulize.underscore.pluralize
      @item_id = self.connection.select_value("SELECT item_id FROM #{table_name} WHERE id = #{self.id}").to_i
    end
    return @item_id
  end
  
  
  ItemProfileType.cached_list.keys.each do |key|
    self.class_eval %{
      def #{key}
        read_profile(#{key.inspect})
      end
      
      def #{key}=(val)
        set_profile(#{key.inspect}, val)
      end
      
      def #{key}?
        #{key}.present?
      end
    }
  end
  
  def item_type
    ActiveSupport::StringInquirer.new(self[:item_type])
  end
  
  delegate :product?, :meal?, :menu?, :bundle?, :to => :item_type
  
  def read_profile(attr)
    list = ItemProfileType.cached_list
    attr = attr.to_s
    @profiles = {} unless(@profiles.is_a? Hash)
    if(@profiles[list[attr]])
      return @profiles[list[attr]]
    else
      self.item_profiles.each do |profile|
        @profiles[profile.field_type] ||= profile.field_body
      end
      return @profiles[list[attr]]
    end
  end

  def set_profile(attr, value)
    list = ItemProfileType.cached_list
    @profiles = {} unless(@profiles.is_a? Hash)
    @profiles[list[attr]] = value
    @profiles_changed ||= []; @profiles_changed.push list[attr]
  end

  def update_profiles
    return unless @profiles_changed
    query = "DELETE FROM item_profiles WHERE item_id = #{self.item_id} AND field_type IN (#{@profiles_changed.join(',')});"
    self.connection.execute query
    @profiles.each do |type_id, value|
      ItemProfile.create({:item_id => self.item_id, :field_body => value, :field_type => type_id})
    end
    self.item_profiles.reload
    true
  end

  def discount_price options={}
    discount = 0
    for d in self.item_discounts
      discount += d[:amount] if d.active? options[:date]
    end
    if  options[:user]
      user = options[:user]
    elsif UserSystem.current_user.class == User
      user = UserSystem.current_user
    end
    if user
      discounts = user.active_discounts :date => options[:date], :item_type => self.item_type
      for d in discounts
        discount += d[:amount]
      end
    end
    discount = (1-discount < 0 )? 0 : (1-discount)
    return price * discount
  end

  def save_image image, dimensions = "300x200"
      inpath = %{#{RAILS_ROOT}/tmp/upload/#{UserSystem.current_user.id}/#{image}}
      outpath = %{#{RAILS_ROOT}/public/pictures/item_#{self.item_id}.jpg}
      thpath = %{#{RAILS_ROOT}/public/pictures/item_#{self.item_id}.th.jpg}
      File.unlink outpath if File.exists? outpath
      File.unlink thpath if File.exists? thpath
      self['image_flag'] = system("convert #{inpath} -resize '#{dimensions}>' #{thpath}")
      self.save
      FileUtils.move inpath, outpath
  end

  # used instead of set_primary_key to get rid of strange association errors
  def self.primary_key
    "item_id"
  end

  protected

  def set_updated_by
    self.last_update_by = UserSystem.current_user
    self.updated_at = Time.now
  end

  def ignore_item_id
    @ignore_item_id = true
  end

  def unignore_item_id
    @ignore_item_id = false
  end

  def ignore_item_type
    @ignore_item_type = true
  end

  def unignore_item_type
    @ignore_item_type = false
  end

  private

  # overriding ActiveRecord's method to remove broken includes
  def self.find_every options
    bad_includes = [:item_discounts, :item_profiles, :ordered_items]
    options[:include].delete_if do |i|
      bad_includes.include?(i)
    end if options[:include].is_a? Array

    options[:include].delete_if do |k,v|
      bad_includes.include?(k) ||  bad_includes.include?(v)
    end if options[:include].is_a? Hash
    super
  end


end
