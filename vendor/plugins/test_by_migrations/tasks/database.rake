module Rake
  class Application
    def remove_task(task_name)
      @tasks.delete(task_name.to_s)
    end
  end
end

namespace :db do
  namespace :test do
    desc 'Build the test database from migrations'
    task :build_from_migrations => ["db:test:purge"] do
      ActiveRecord::Base.establish_connection(:test)
      ActiveRecord::Schema.verbose = false
      Rake::Task["db:migrate"].invoke
      # TODO: prevent rails from deleting all data from the database.
    end
    
    Rake.application.remove_task('db:test:prepare')
    
    desc 'Prepare the test database and load the schema'
    task :prepare => %w(environment db:abort_if_pending_migrations) do
      if defined?(ActiveRecord) && !ActiveRecord::Base.configurations.blank?
        Rake::Task[{ :sql  => "db:test:clone_structure", :ruby => "db:test:build_from_migrations" }[ActiveRecord::Base.schema_format]].invoke
      end
    end
  end
end

