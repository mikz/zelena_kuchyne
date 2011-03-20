
default_run_options[:pty] = true
ssh_options[:forward_agent] = true
require 'bundler/capistrano'

$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano"

set :scm, :git
set :group, :www
set :branch, :master
set :deploy_via, :remote_cache
set :git_shallow_clone, 1

#before 'deploy:finalize_update' do
#  run "cd #{current_path} && git submodule update --init --recursive"
#end
set :use_sudo, false
set :deploy_to, "/var/www/#{application}"

server "o2h.cz", :web, :app, :db, :primary => true

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

task :set_permissions do
  run "chgrp -R #{group} #{deploy_to}"
end

namespace :rvm do
  task :trust_rvmrc do
    run "rvm rvmrc trust #{release_path}"
  end
end

after :'deploy:finalize_update', :set_permissions, :roles => :web
after :'deploy:update_code', :'rvm:trust_rvmrc', :roles => :app