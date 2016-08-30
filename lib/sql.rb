#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true

require 'pg'

# Class for executing SQL
# :reek:TooManyInstanceVariables
class SQL
  def initialize dbname, logger = nil
    @dbname = dbname
    @logger = logger
    @db = PG.connect dbname: @dbname
    @message = Messages.new
  end

  def query statement, *arguments
    @error_message = nil
    @logger.info "#{statement}: #{arguments}" if @logger
    @db.exec_params statement, arguments
  rescue PG::UniqueViolation
    save_error @message.error(:list_name_unique)
  rescue PG::Error => exception
    save_error "#{exception.class}: #{exception}"
  end

  def error_message
    @message.error(@error_message) || @error_message if @error_message
  end

  def finish
    @db.finish
  end

  def save_error message
    @error_message = message
    nil
  end

  def update_error message
    @error_message = message unless @error_message
    nil
  end
end
