#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true

# Sinatra helpers
module Helpers
  def all_lists
    @lists ||= @storage.all_lists
  end

  def app_name
    @message.ui :app_name
  end

  def app_title
    @message.ui :app_title
  end

  # :reek:UtilityFunction
  def list_complete? list
    list[:todos_count].positive? && list[:todos_remaining_count].zero?
  end

  def list_completion_class list
    list_complete?(list) ? 'complete' : 'incomplete'
  end

  # :reek:UtilityFunction
  def todo_completion_class todo
    todo[:completed] ? 'complete' : 'incomplete'
  end

  # :reek:UtilityFunction
  def todos_count todos
    todos.size
  end

  def todo_items list_id
    @todos ||= @storage.find_todo_items list_id
  end

  def todo_list list_id
    @list ||= @storage.find_todo_list list_id
  end

  # :reek:UtilityFunction
  def todos_remaining_count todos
    todos.count { |todo| !todo[:completed] }
  end
end
