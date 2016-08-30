#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true

require_relative 'sql'

# :reek:UtilityFunction
def testing?
  ENV['RACK_ENV'] == 'test'
end

# :nocov:
DBNAME ||=
  if testing?
    'todos.test'
  elsif development?
    'todos.devel'
  else
    'todos'
  end
# :nocov:

# Used SQL commands
module DatabasePersistenceCommands
  COMMAND = {
    count_lists:         'SELECT COUNT(*) FROM lists',
    create_todo_item:    'INSERT INTO todos (list_id, name) VALUES ($1, $2)',
    create_todo_list:    'INSERT INTO lists (name) VALUES ($1)',
    delete_todo_item:    'DELETE FROM todos WHERE list_id = $1 AND id = $2',
    delete_todos_all:    'DELETE FROM todos WHERE list_id = $1',
    delete_todo_list:    'DELETE FROM lists WHERE id = $1',
    get_all_todo_lists:  <<~SQL,
      SELECT lists.*,
             COUNT(todos.id)                      AS todos_count,
             COUNT(NULLIF(todos.completed, true)) AS todos_remaining_count,
             COUNT(todos.id) > 0 AND COUNT(NULLIF(todos.completed, true)) = 0
                                                  AS completed
      FROM lists
      LEFT JOIN todos ON todos.list_id = lists.id
      GROUP BY lists.id
      ORDER BY completed, lists.name
    SQL
    get_todo_items:      <<~SQL,
      SELECT * FROM todos
      WHERE list_id = $1
      ORDER BY completed, name
    SQL
    get_todo_list:       <<~SQL,
      SELECT lists.*,
             COUNT(todos.id)                      AS todos_count,
             COUNT(NULLIF(todos.completed, true)) AS todos_remaining_count,
             COUNT(todos.id) > 0 AND COUNT(NULLIF(todos.completed, true)) = 0
                                                  AS completed
      FROM lists
      LEFT JOIN todos ON todos.list_id = lists.id
      WHERE lists.id = $1
      GROUP BY lists.id
      ORDER BY completed, lists.name
    SQL
    mark_todo:           'UPDATE todos SET completed = $3 ' \
                         'WHERE list_id = $1 AND id = $2',
    mark_todos_complete: 'UPDATE todos SET completed = true ' \
                         'WHERE list_id = $1',
    update_list_name:    'UPDATE lists SET name = $2 WHERE id = $1'
  }.freeze
end

# Provide database persistence of session data
# :reek:TooManyMethods
#
# Tuple of todo values
# { id: integer, name: string, completed: boolean, list_id: integer }
#
# Tuple of list values
# { id: integer, name: string, todos: array-of-todo-value-tuples }
class DatabasePersistence
  include DatabasePersistenceCommands

  def initialize dbname = DBNAME, logger: nil
    @sql = SQL.new dbname, logger
  end

  # Returns Arrray of list tuple values or nil
  def all_lists
    query(:get_all_todo_lists).map { |tuple| todo_list tuple }
  end

  # Returns true on success, false otherwise
  def create_todo_item list_id, todo_name
    update :create_todo_item, list_id, todo_name
  end

  # Returns pg_result on success, nil otherwise
  def create_todo_list name
    update :create_todo_list, name
  end

  # Returns true on success, false if no such list, nil on error
  def delete_todo_list id
    when_list_exists id do
      delete_todos_all id
      update :delete_todo_list, id
    end
  end

  # Returns true on success, false if nothing deleted, nil on error
  def delete_todo_item list_id, todo_id
    when_list_exists(list_id) { update :delete_todo_item, list_id, todo_id }
  end

  # Returns true on success, false if nothing deleted, nil on error
  def delete_todos_all list_id
    when_list_exists(list_id) { update :delete_todos_all, list_id }
  end

  def error_message
    @sql.error_message
  end

  # Returns list of todo item tuples
  def find_todo_items id
    pg_result = query :get_todo_items, id
    return unless pg_result

    pg_result.map { |tuple| todo_item tuple }
  end

  # Returns tuple of list values or nil
  def find_todo_list id
    pg_result = query :get_todo_list, id
    if pg_result.ntuples.zero?
      @sql.save_error :no_todos_list
      return nil
    end

    todo_list pg_result.first
  end

  def finish
    @sql.finish
  end

  # Returns true on success, false if nothing marked, nil on error
  def mark_all_complete id
    when_list_exists(id) { update :mark_todos_complete, id }
  end

  # Returns true on success, false if nothing updated, nil on error
  def mark_todo list_id, todo_id, completed
    when_list_exists list_id do
      ok = update :mark_todo, list_id, todo_id, completed
      @sql.update_error :no_todo unless ok
      ok
    end
  end

  # Returns number of lists or nil on error
  def size
    pg_result = query :count_lists
    pg_result.first['count'].to_i
  end

  # Returns true on success, false if nothing modified, nil on error
  def update_list_name id, new_name
    when_list_exists(id) { update :update_list_name, id, new_name }
  end

  private

  def query command_id, *arguments
    @sql.query COMMAND[command_id], *arguments
  end

  def todo_item tuple
    {
      id:        tuple['id'].to_i,
      name:      tuple['name'],
      completed: tuple['completed'] == 't',
      list_id:   tuple['list_id'].to_i
    }
  end

  def todo_list tuple
    {
      id:                    tuple['id'].to_i,
      name:                  tuple['name'],
      todos_remaining_count: tuple['todos_remaining_count'].to_i,
      todos_count:           tuple['todos_count'].to_i,
      completed:             tuple['completed'] == 't'
    }
  end

  def update command_id, *arguments
    pg_result = @sql.query COMMAND[command_id], *arguments
    return unless pg_result

    pg_result.cmd_tuples.positive?
  end

  def when_list_exists id
    return yield if find_todo_list id

    @sql.save_error :no_todos_list
    false
  end
end
