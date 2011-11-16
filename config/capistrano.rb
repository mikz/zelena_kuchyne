set :rvm_ruby_string, 'ree@zk'
set :domain, "zelenakuchyne.cz"
set :application, 'zelena_kuchyne'

server fetch(:domain), :app, :db, :web
