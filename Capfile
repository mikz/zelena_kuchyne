load 'deploy' if respond_to?(:namespace) # cap2 differentiator

require 'o2h/capistrano'
require 'o2h/capistrano/deploy/passenger'

Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

load 'config/capistrano'
