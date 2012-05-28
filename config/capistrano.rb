set :gateway, 'mikz@de.o2h.cz'
set :domain, "zelenakuchyne.cz"
set :application, 'zelena_kuchyne'

set :user, 'hosting'

server 'hosting', :app, :db, :web, :primary => true
