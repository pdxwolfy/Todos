#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true

require 'minitest/unit'
require 'open3'
require 'singleton'

make_my_diffs_pretty!

# Execute error for external command
class ExecError < RuntimeError; end

# Handles one-time creation and deletion of standalone unit test database
class UnitTestDatabaseMaker
  include Singleton

  SCHEMA ||= 'schema.sql'
  MESSAGE ||= {
    createdb_notice: "database creation failed: ERROR:  database #{DBNAME} " \
                     "already exists\n",
    dropdb_notice:   "NOTICE:  database #{DBNAME} does not exist, skipping\n",
    no_lists_table:  "ERROR:  table lists does not exist\n",
    no_todos_table:  "ERROR:  table todos does not exist\n"
  }.freeze

  def initialize
    ObjectSpace.define_finalizer(self, self.class.finalize)
    return if @database_created

    drop_existing_database
    create_database
    @database_created = true
  end

  def reset
    schema = File.read(SCHEMA)
    command = ['psql', '--quiet', '-d', DBNAME]
    run2e(*command, stdin_data: schema) do |outerr|
      outerr.gsub! MESSAGE[:no_todos_table], ''
      outerr.gsub! MESSAGE[:no_lists_table], ''
    end
  end

  private

  def create_database
    run2e 'createdb', DBNAME do |outerr|
      outerr.gsub! MESSAGE[:createdb_notice], ''
    end
  end

  def drop_existing_database
    run2e 'dropdb', '--if-exists', DBNAME do |outerr|
      outerr.gsub! MESSAGE[:dropdb_notice], ''
    end
  end

  def run2e *command, stdin_data: ''
    outerr, status = Open3.capture2e(*command, stdin_data: stdin_data)
    raise ExecError, "#{command.join ' '}\n#{outerr}" unless status.success?

    outerr = yield outerr
    puts outerr if outerr
  end

  class << self
    def finalize
      proc { system 'dropdb', DBNAME }
    end
  end
end

before do
  @message = Messages.new

  remove_data_path
  create_data_path

  UnitTestDatabaseMaker.instance.reset
end

after do
  remove_data_path
end
