desc "Build the application environment from scratch. (lets you configure the database, creates schema, etc...)"
task :bootstrap => ["bootstrap:default"]

# SILENCE!! You heard me??!!
def silent(&block)
  return yield if ENV['VERBOSE']

  `stty -echo`
  begin
    silence_stream(STDERR) do
      silence_stream(STDOUT) do
        yield
      end
    end
    `stty echo`
  rescue Exception => e
    `stty echo`
    raise e
  end
end

namespace :bootstrap do
  
  task :default => [:db_config, :reload_db, :default_values, :configuration] do
    print "Bootstrap process finished\n"
  end
  
  desc "Create a database.yml file and edit it in your editor unless it already exists"
  task :db_config => ["#{RAILS_ROOT}/config/database.yml"]
  
  file "#{RAILS_ROOT}/config/database.yml" do
    fail "Set the environment variable EDITOR to your favourite editor or pass it as a parameter" unless ENV['EDITOR']
    
    FileUtils.cp("#{RAILS_ROOT}/config/database_default.yml", "#{RAILS_ROOT}/config/database.yml")
    `#{ENV['EDITOR']} #{RAILS_ROOT}/config/database.yml`
  end
  
  desc "(Re)build the database schema"
  task :reload_db => [:down, :up]
  
  task :down => [:environment] do
    print "Cleaning the database\n"
    if ENV['VERBOSE'] and ENV['VERBOSE'] == 'true'
      ActiveRecord::Migration.verbose = true
      ActiveRecord::Migrator.migrate("db/migrate/", 0)
    else
      silent do
        ActiveRecord::Migrator.migrate("db/migrate/", 0)
      end
    end
  end
  
  task :up => [:down] do
    print "Running migrations up to #{(ENV["VERSION"] ? "version #{ENV["VERSION"]}" : "current version")}\n"
    
    if ENV['VERBOSE'] and ENV['VERBOSE'] == 'true'
      ActiveRecord::Migration.verbose = true
      ActiveRecord::Migrator.migrate("db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    else
      silent do
        ActiveRecord::Migrator.migrate("db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
      end
    end
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
  end
  
  desc "Interactive wizard that lets you configure the application"
  task :configuration => ["#{RAILS_ROOT}/config/database.yml", :environment, :reload_db, :default_values] do
    pass1 = false
    pass2 = true
    
    while true
      print "Set password for user 'admin': "
      silent do
        pass1 = STDIN.gets.chop
      end
      print "\n"
    
      print "Type the password again: "
      silent do
        pass2 = STDIN.gets.chop
      end
      print "\n"
      
      if pass1 == pass2
        break
      else
        print "Passwords are different!\n\n"
      end
    end
    
    sql = <<SQL
INSERT INTO users(login, email) VALUES
       ('admin', 'admin@zelenakuchyne.cz');
    
UPDATE users SET
  salt = encode(digest('--' || NOW() || '--admin--', 'sha256'::text), 'hex')
    WHERE login = 'admin';

UPDATE users SET
  password_hash = encode(digest('--' || salt || '--#{pass1}--', 'sha256'::text), 'hex')
    WHERE login = 'admin';

INSERT INTO memberships(user_id, group_id) VALUES
  ( (SELECT id FROM users WHERE login = 'admin'), (SELECT id FROM groups WHERE system_name = 'admins') );
SQL
    silent do
      ActiveRecord::Migration.execute(sql)
    end
    
    default_language = 'cs'
    delivery_from = '10:30'
    delivery_to = '15:30'
    delivery_step = '1800'
    default_pagination = '30'
    
    print "Set configuration options, please (default values are in parentheses)\n"
    print "default language (cs): "
    a = STDIN.gets.chop
    default_language = a if a != ''
    
    print "delivery starts at (10:30): "
    a = STDIN.gets.chop
    delivery_from = a if a != ''
        
    print "delivery stops at (15:30): "
    a = STDIN.gets.chop
    delivery_to = a if a != ''

    print "delivery interval in seconds (1800): "
    a = STDIN.gets.chop
    delivery_step = a if a != ''
        
    print "default number of items per page of listing (30): "
    a = STDIN.gets.chop
    default_pagination = a if a != ''
    
    sql = <<SQL    
INSERT INTO configuration(key, value) VALUES
      ('default_language', '#{default_language}'),
      ('delivery_from', '#{delivery_from}'),
      ('delivery_to', '#{delivery_to}'),
      ('delivery_step', '#{delivery_step}'),
      ('default_pagination', '#{default_pagination}');
SQL
    silent do
      ActiveRecord::Migration.execute(sql)
    end
  end
  
  desc "Load default values"
  task :default_values => ["#{RAILS_ROOT}/config/database.yml", :environment] do
    print "Initializing the database with default values\n"
    sql = File.open("#{RAILS_ROOT}/db/bootstrap/default_values.postgresql.sql", 'r').read
    silent do
      ActiveRecord::Migration.execute(sql)
    end
  end
  
  desc "Load sample content (ONLY FOR DEVELOPMENT AND TESTING PURPOSES)"
  task :sample_content => ["#{RAILS_ROOT}/config/database.yml", :environment] do
    print "Loading sample content for testing\n"
    sql = File.open("#{RAILS_ROOT}/db/bootstrap/sample_content.postgresql.sql", 'r').read
    silent do
      ActiveRecord::Migration.execute(sql)
    end
  end
  
  
  desc "Create backup of database with pg_dump"
  task :backup => ["#{RAILS_ROOT}/config/database.yml", :environment] do
    db_config = ActiveRecord::Base.configurations[RAILS_ENV]
    backup_file = File.join(ENV['DIR'] || '.', Time.now.strftime("backup_%Y%m%d%H%M%S.sql"))
    verbose = ENV['VERBOSE']
    pg_dump = nil
    ["/usr/lib/postgresql/8.3/bin/pg_dump","/usr/local/pgsql/bin/pg_dump",%x{which pg_dump}.strip].each do |pg|
      pg_dump ||= pg if File.exists? pg    
    end
    if !pg_dump
      fail "ERROR: pg_dump binary not found"
    end
    print "Creating backup of #{RAILS_ENV} environment to '#{backup_file}'\n"
    command = %{#{pg_dump} -T schema_migrations #{"-p #{db_config['port']} " if db_config['port']} -h #{db_config["host"]} -U #{db_config["username"]} --verbose --data-only --column-inserts --disable-triggers #{db_config["database"]} -f #{backup_file}}
    
    verbose ? %x{#{command}} :  silent do
      %x{#{command}}
    end

    print "Backup created\n"
    @backup_file = backup_file
    
    if ENV['MAILTO']
      %x{bzip2 #{backup_file.inspect}}
      @backup_file << ".bz2"
      mutt = "mutt"
      mutt << " -s #{ENV['SUBJECT']}" if ENV['SUBJECT']
      %x{#{mutt} -a #{@backup_file.inspect} #{ENV['MAILTO'].inspect} < /dev/null}
    end
  end
  
  desc "Update to HEAD and reload db (backup, migrate to V=0, svn up, migrate, load backup)"
  task :update => [:backup, :down, :update_repository, :up, :load_backup_file] do
  end
  
  desc "Update repository to HEAD revision"
  task :update_repository do
    print "Updating repository to HEAD revision\n"
    if ENV['VERBOSE'] and ENV['VERBOSE'] == 'true'
      silent do
        %x{svn up}
      end
    else
      %x{svn up}
    end
  end
  
  task :load_backup_file do
    backup_file = @backup_file
    db_config = ActiveRecord::Base.configurations[RAILS_ENV]
    
    if !File.exists?(backup_file)
      fail "Cannot find backup file '#{backup_file}'"
    end
    psql = nil
    ["/usr/local/pgsql/bin/psql",%x{which psql}].each do |pg|
      if File.exists? pg
        psql = pg
      end
    end
    
    fail "ERROR: psql binary not found" if !psql
    print "Loading backup file '#{backup_file}'\n"
    %x{#{psql} -d #{db_config["database"]} #{"-p #{db_config['port']} " if db_config['port']} -U postgres -f #{@backup_file} > /dev/null }
    print "Backup loaded back into database\n"
  end
  
  desc "Unattended database reload (with sample content and default values)"
  task :unattended_reload => [:unattended_create,  :sample_content] do
  end
  
  
  task :unattended_create => ["#{RAILS_ROOT}/config/database.yml", :environment, :reload_db, :default_values] do
    sql = %{
      INSERT INTO configuration(key, value) VALUES
      ('default_language', 'cs'),
      ('delivery_from', '10:30'),
      ('delivery_to', '15:30'),
      ('delivery_step', '1800'),
      ('default_pagination', '30');
    }
    
    silent do
      ActiveRecord::Migration.execute(sql)
    end
    
    sql = %{
    INSERT INTO users(login, email) VALUES
           ('admin', 'admin@zelenakuchyne.cz');

    UPDATE users SET
      salt = encode(digest('--' || NOW() || '--admin--', 'sha256'), 'hex')
        WHERE login = 'admin';

    UPDATE users SET
      password_hash = encode(digest('--' || salt || '--admin--', 'sha256'), 'hex')
        WHERE login = 'admin';

    INSERT INTO memberships(user_id, group_id) VALUES
      ( (SELECT id FROM users WHERE login = 'admin'), (SELECT id FROM groups WHERE system_name = 'admins') );
    }
    silent do
      ActiveRecord::Migration.execute(sql)
    end
    
  end
end
