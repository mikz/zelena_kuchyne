# -*- encoding : utf-8 -*-
require 'exposure'
require 'exposure_helper'
ActionController::Base.send :include, Exposure
ActionView::Base.send :include, ExposureHelper

