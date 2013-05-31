require "rails/generators/active_record"

module RailsConnector
  module Generators
    class CommentsGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      desc "Create a migration to create comments in your application."
      def generate_migration
        migration_template 'migration.rb', 'db/migrate/create_comments.rb'
      end
    end
  end
end