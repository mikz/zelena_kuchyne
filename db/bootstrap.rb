# -*- encoding : utf-8 -*-
#!/usr/bin/env ruby
require 'rubygems'
require 'postgres-pr/connection'
require 'yaml'
require 'optparse'

$options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: bootstrap.rb [options]"
  opts.on '--environment', '-e [E]', 'Rails environment (usually production|development|test)' do |e|
    $options[:env] = e
  end
  opts.on '--config-file', '-c [C]', 'Config file location' do |c|
    $options[:config_file] = c
  end
  opts.on '--reload-database', '-B', 'Regenerate the database' do |b|
    $options[:reload_db] = true
  end
  opts.on '--load-sample-content', '-S', 'Load the sample content' do |s|
    $options[:sample_content] = true
  end
  opts.on '--no-default-values', '-D', 'Do not load default values' do |d|
    $options[:no_default_values] = true
  end
  opts.on '--verbose', '-v', 'Verbose' do |v|
    $options[:verbose] = true
  end
end.parse!

# find the directory where bootstrap.rb sits
$options[:directory] = "#{File.dirname(File.expand_path($0))}"

#defaults
$options[:env] ||= 'development'
$options[:config_file] ||= "#{$options[:directory]}/../config/database.yml"
$options[:reload_db] ||= false
$options[:sample_content] ||= false
$options[:lo_classes] ||= []
$options[:verbose] ||= false

# load db credentials from the rails config file
db_config = YAML::load(File.open($options[:config_file]))
$options[:db] = db_config[$options[:env]]['database']
$options[:user] = db_config[$options[:env]]['username']
$options[:pwd] = db_config[$options[:env]]['password'] || ''
$options[:host] = db_config[$options[:env]]['host'] || 'localhost'
$options[:port] = db_config[$options[:env]]['port'] || 5432

if(defined? PostgresPR)
  adapter = PostgresPR
elsif(defined? Postgres)
  adapter = Postgres
else
  raise "No suitable database adapter found."
end

$conn = adapter::Connection.new($options[:db], $options[:user], $options[:pwd], "tcp://#{$options[:host]}:#{$options[:port]}")

if $options[:reload_db]

  files = %w{
    clean
    configuration
    pages
    users
    items
    meals
    bundles
    products
    orders
    discounts
    country_codes
    items_views
    meals_views
    orders_views
    additional_views
    users_func
    items_func
    meals_func
    products_func
    orders_func
    discounts_func
  }
  files.push "default_values" unless $options[:no_default_values]
  
  STDERR << "Now processing SQL files...\n"
  
  files.each do |file|
    STDERR << "Processing: #{file}\n"
    begin
      q = File.open("#{$options[:directory]}/bootstrap/#{file}.sql").read
      q = "BEGIN;\n#{q}\nCOMMIT;"
      STDERR << "Executing:\n#{q}\n" if $options[:verbose]
      $conn.query q
    rescue
      STDERR << "#{$!.to_s}\n"
      break;
    end
  end
end

if $options[:sample_content]
  STDERR << "Now processing sample content...\n"
  begin
    path = "#{$options[:directory]}/bootstrap/sample_content.sql"
    q = File.open(path).read
    q = "BEGIN;\n#{q}\nCOMMIT;"
    STDERR << "Executing:\n#{q}\n" if $options[:verbose]
    $conn.query q
  rescue
    STDERR << "#{$!.to_s}\n"
    break;
  end
end

