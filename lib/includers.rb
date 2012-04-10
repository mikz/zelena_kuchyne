# -*- encoding : utf-8 -*-
# This module provides a simple way to include javascripts and stylesheets from controllers
# 
# Usage:
#   class PostsController < ApplicationController
#     include_javascripts 'posts', 'datepicker'
#     include_stylesheets 'admin', :only => [:edit]
# 
# included javascripts and stylesheets are added via before_filter
# and they're available in helpers via @javascripts and @styleshets.
module Includers
  def self.included(base)
    base.class_eval do
      def self.include_javascripts(*args)
        options = args.extract_options!
        javascripts = args || []
        append_before_filter(options) { |c| c.pass_javascripts(javascripts) }
      end
    
      def self.include_stylesheets(*args)
        options = args.extract_options!
        stylesheets = args || []
        append_before_filter(options) { |c| c.pass_stylesheets(stylesheets) }
      end
    end
  end
  
  def pass_javascripts(javascripts)
    @javascripts ||= Array.new
    @javascripts = @javascripts | javascripts
  end
  def pass_stylesheets(stylesheets)
    @stylesheets ||= Array.new
    @stylesheets = @stylesheets | stylesheets
  end
end

