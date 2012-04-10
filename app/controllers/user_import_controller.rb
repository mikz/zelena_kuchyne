# -*- encoding : utf-8 -*-
class UserImportController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins)}
  include_stylesheets 'user_import', 'jquery.colorpicker', 'jquery.autocomplete'
  include_javascripts 'user_form', 'jquery.colorpicker', 'jquery.autocomplete'
  
  def index
  end
  
  def match_users
    @users = UserImport.find :all, :conditions => "user_id IS NULL", :include => {:user => :user_profiles }
    @users.each do |u|
      u.match_user :method => :email
      u.save if u.user_id_changed?
    end
  end
  
  def manual_match_users
    @users = UserImport.find :all, :conditions => "user_id IS NULL", :include => {:user => :user_profiles }
  end
  
  def assoc_user
    @user_import = UserImport.find_by_iduziv params[:id]
    @user = User.find_by_login params[:user]
    @user_import.user_id = @user.id
    @user_import.save
    respond_to do |format| 
      format.js {
        render :update do |page|
          page.hide "user_import_#{params[:id]}"
        end
      }
    end
  end

  
  def hide_user
    respond_to do |format|
      format.js {
        render :update do |page|
          page.hide "user_import_#{params[:id]}"
        end
      }
    end
  end
  
  def clean_users
    @old_records = UserImport.find :all
    UserImport.delete_all "(objednavek = 0 AND cena_objednavek = 0 ) OR ( objednavek < 4 AND last_order::date < '2008-01-01'::date ) OR (last_order < '2007-01-01'::date)"
    @new_records = UserImport.find :all
  end
  
  def check_users
    @users = User.find :all
    @imported_users = UserImport.find :all
    @valid = UserImport.find :all, :conditions => "user_id IS NOT NULL"
    @updated_users = UserImport.find :all, :conditions => "updated = true"
    @bad_associations = UserImport.find_bad_associations
  end
  
  def edit_user
    @user = User.find_by_id params[:id]
    @groups = Group.find :all
    @country_codes = CountryCode.find :all, :select => "code", :group => "code", :order => "code"
    respond_to do |format|
      format.js {
        render :update do |page|
          content_for :submit_button do
            "<input type=\"submit\" value=\"Odeslat\"/> #{link_to_remote "zavřít", :url => { :action => :close_user, :id => @user.id } }"
          end
          page.replace_html "user_#{@user.id}", :partial => "users/form", :locals => {:url => {:controller => :user_import, :action => :update_user, :id => @user.id}}
          page.visual_effect :highlight, "user_#{@user.id}"
        end
      }
    end
  end
  
  def close_user
    @user = User.find_by_id params[:id]
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html "user_#{@user.id}", :partial => "user_fieldset", :locals => {:user => @user}
          page.visual_effect :highlight, "user_#{@user.id}"
        end
      }
    end
  end
  
  def show_user
    @user = User.find_by_id params[:id]
    respond_to do |format|
      format.js {
        render :update do |page|
          content_for :close_button do
            "#{link_to_remote "zavřít", :url => { :action => :close_user, :id => @user.id } }"
          end
          page.replace_html "user_#{@user.id}", :partial => "users/show_user", :locals => {:user => @user}
          page.visual_effect :highlight, "user_#{@user.id}"
        end
      }
    end
  end
  
  def update_user
    @user = User.find_by_id params[:id]
    @user.imported_orders_price = params[:user]['imported_orders_price']
    if(@user.update_attributes(params[:user]) && @user.errors.empty?)
      respond_to do |format|
        format.js {
          render :update do |page|
            page.replace_html "user_#{@user.id}", :partial => "user_fieldset", :locals => {:user => @user}
            page.visual_effect :highlight, "user_#{@user.id}"
          end
        }
      end
    else
      respond_to do |format|
        format.js {
          render :update do |page|
            page.replace_html "user_#{@user.id}", :partial => "users/form", :locals => {:url => {:controller => :user_import, :action => :update_user, :id => @user.id}}
            page.visual_effect :highlight, "user_#{@user.id}"
          end
        }
      end
    end
  end
  
  def validate_user
    @user_import = UserImport.find :first, :conditions => ["updated = false AND user_id IS NOT NULL AND skip = false"], :order => "last_order ASC", :include => :user
    @user = @user_import.user
    @groups = Group.find :all
    @country_codes = CountryCode.find :all, :select => "code", :group => "code", :order => "code"
  end
  
  def save
    @user_import = UserImport.find_by_iduziv params[:user_import_id]
    @user        = User.find_by_id params[:user_id]
    @groups = Group.find :all
    @country_codes = CountryCode.find :all, :select => "code", :group => "code", :order => "code"
    
    @user.imported_orders_price = params[:user]['imported_orders_price']
    if(@user.update_attributes(params[:user]) && @user.errors.empty?)
      @user_import.updated = true
      @user_import.save
      respond_to do |format|
        format.js {
          render :update do |page|
            page << "window.location.reload()"
          end
        }
      end
    else
      respond_to do |format|
        format.js {
          render :update do |page|
            page.replace_html "user", :partial => "users/form", :locals => {:url => {:controller => :user_import, :action => :save, :user_id => @user.id, :user_import_id => @user_import.id }}
            page.visual_effect :highlight, "user"
          end
        }
      end
    end
  end
  
  def skip
    @user_import = UserImport.find_by_iduziv params[:id]
    @user_import.update_attribute("skip",true)
    respond_to do |format|
      format.js do
        render :update do |page|
          page << "window.location.reload()"
        end
      end
    end
  end
  
  def merge
    @users = UserImport.find :all, :conditions => ["iduziv IN (?)", params[:ids]]
    params[:what].each { |w|
      count = 0
      @users.each do |u|
        count += u.send(w)
      end
      @users.each do |u|
        u.update_attribute w, count
      end
    }
    respond_to do |format|
      format.js {
        render :update do |page|
          page << "window.location.reload()"
        end
      }
    end
  end
  
  def destroy
    @user = UserImport.find_by_iduziv params[:id]
    @user.destroy
    respond_to do |format|
      format.js {
        render :update do |page|
          page << "window.location.reload()"
        end
      }
    end
  end
end

