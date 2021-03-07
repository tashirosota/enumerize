# frozen_string_literal: true

require 'test_helper'
require 'active_record'
require 'logger'

db = (ENV['DB'] || 'sqlite3').to_sym

silence_warnings do
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Base.logger = Logger.new(nil)
  ActiveRecord::Base.configurations = {
    'sqlite3' => {
      'adapter' => 'sqlite3',
      'database' => ':memory:'
    },
    'postgresql' => {
      'adapter' => 'postgresql',
      'host' => 'localhost',
      'username' => ENV['POSTGRES_USER'],
      'password' => ENV['POSTGRES_PASSWORD'],
      'database' => 'enumerize_test',
    },
    'postgresql_master' => {
      'adapter' => 'postgresql',
      'host' => 'localhost',
      'username' => ENV['POSTGRES_USER'],
      'password' => ENV['POSTGRES_PASSWORD'],
      'database' => 'template1',
      'schema_search_path' => 'public'
    }
  }
  if db == :postgresql
    ActiveRecord::Base.establish_connection(:postgresql_master)
    ActiveRecord::Base.connection.recreate_database('enumerize_test')
  end

  ActiveRecord::Base.establish_connection(db)
end

ActiveRecord::Base.connection.instance_eval do
  create_table :users do |t|
    t.string :sex
    t.string :role
    t.string :lambda_role
    t.string :name
    t.string :interests
    t.integer :status
    t.text :settings
    t.integer :skill
    t.string :account_type, :default => :basic
    t.string :foo
  end

  create_table :documents do |t|
    t.integer :user_id
    t.string :visibility
    t.integer :status
    t.timestamps null: true
  end
end

class BaseEntity < ActiveRecord::Base
  self.abstract_class = true

  extend Enumerize
  enumerize :visibility, :in => [:public, :private, :protected], :scope => true, :default => :public
end

class Document < BaseEntity
  belongs_to :user

  enumerize :status, in: {draft: 1, release: 2}
end

module RoleEnum
  extend Enumerize
  enumerize :role, :in => [:user, :admin], :default => :user, scope: :having_role
  enumerize :lambda_role, :in => [:user, :admin], :default => lambda { :admin }
end

class User < ActiveRecord::Base
  extend Enumerize
  include RoleEnum

  store :settings, accessors: [:language]

  enumerize :sex, :in => [:male, :female], scope: :shallow
  enumerize :language, :in => [:en, :jp]

  serialize :interests, Array
  enumerize :interests, :in => [:music, :sports, :dancing, :programming], :multiple => true

  enumerize :status, :in => { active: 1, blocked: 2 }, scope: true

  enumerize :skill, :in => { noob: 0, casual: 1, pro: 2 }, scope: :shallow

  enumerize :account_type, :in => [:basic, :premium]

  # There is no column for relationship enumeration for testing purposes: model
  # should not be broken even if the associated column does not exist yet.
  enumerize :relationship, :in => [:single, :married]

  has_many :documents
end

describe Enumerize::ActiveRecordSupport do
  it 'supports defining enumerized attributes on abstract class' do
    Document.delete_all

    pp 'ここから気になってるところ'
    document = Document.new
    document.visibility = :protected
    document.visibility.must_equal 'protected'
  end
end
