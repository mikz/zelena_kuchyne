set :gateway, 'mikz@de.o2h.cz'
set :domain, "zelenakuchyne.cz"
set :application, 'zelena_kuchyne'

set :repository, "git@github.com:mikz/zelena_kuchyne.git"
set :user, 'hosting'

server 'hosting', :app, :db, :web, :primary => true
