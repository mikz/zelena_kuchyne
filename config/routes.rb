# -*- encoding : utf-8 -*-
ActionController::Routing::Routes.draw do |map|
  map.resources :menu, :only => [:show], :collection => [:feed, :print]
  map.resource :mass_menu, :only => [:show, :create, :update], :controller => :mass_menu

  map.root :controller => 'welcome'
  
  map.signin 'signin', :controller => 'users', :action => 'signin'
  map.formatted_signin '/signin.:format', :controller => 'users', :action => 'signin'
  map.signup 'signup', :controller => 'users', :action => 'new'
  map.formatted_signup '/signup.:format', :controller => 'users', :action => 'new'
  map.signout 'signout', :controller => 'users', :action => 'signout'
  map.formatted_signout '/signout.:format', :controller => 'users', :action => 'signout'
  
  map.namespace(:mail) do |mail|
    map.connect ':controller.:format'
    map.connect ':controller/:action.:format'
    map.connect ':controller/:action/:id'
    map.connect ':controller/:action/:id.:format'
  end
  
  map.connect 'javascripts/fckeditor/editor/dialog/fck_image.html', :controller => :images, :action => :image_upload, :method => :post
  map.connect ':controller.:format'
  map.connect ':controller/:action.:format'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
  map.connect "dnesni_menu_restaurace", :controller => "dialy_menus", :action => "show", :id => nil
  
  map.page ':id', :controller => 'pages', :action => 'show'
end

