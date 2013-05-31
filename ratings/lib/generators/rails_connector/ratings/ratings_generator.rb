require "rails/generators/active_record"

module RailsConnector
  module Generators
    class RatingsGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      desc "Copy files to your application and create a migration to create ratings."
      def generate_migration
        migration_template 'migration.rb', 'db/migrate/create_ratings.rb'
      end
    end
  end
end