# -*- encoding : utf-8 -*-
env :DIR, '/var/backup/zelena_kuchyne'

set :job_template, 'bash -l -c ":job"'

every 1.day, :at => "02:00 am" do
  rake "bootstrap:backup DIR=$DIR MAILTO=backup@zelenakuchyne.cz"
end

#every 1.day, :at => "02:30 am" do
# command "bzip2 $DIR/*.sql"
#end

