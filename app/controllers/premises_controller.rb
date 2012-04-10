# -*- encoding : utf-8 -*-
class PremisesController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins)}
  include_javascripts 'fckeditor/fckeditor'
  exposure({
    :title => "name",
    :columns => [:name_abbr],
    :form_fields => [
      { :name => :name,        :type => :text_field },
      { :name => :name_abbr,   :type => :text_field },
      { :name => :address,     :type => :text_area },
      { :name => :description, :type => :text_area }
    ]
  })
end

