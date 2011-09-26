require 'active_record'
require 'delayed_job'
require 'logger'
require 'pipeline'
Delayed::Worker.backend = :active_record

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => 'pipeline.sqlite')
ActiveRecord::Migration.verbose = false
ActiveRecord::Base.logger = Logger.new('pipeline.log')
Dir['spec/support/*.rb'].each {|file| require File.join('support', File.basename(file)) }

at_exit do
  File.delete("pipeline.sqlite") if File.exists?("pipeline.sqlite")
  File.delete("pipeline.log") if File.exists?("pipeline.log")
end

