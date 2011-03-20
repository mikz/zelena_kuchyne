load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

load 'config/capistrano/config'
load 'config/capistrano/deploy'
load 'config/capistrano/database'