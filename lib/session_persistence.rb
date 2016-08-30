#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true

# Provide session persistence
class SessionPersistence
  def initialize session
    @session = session
    @session[:lists] ||= []
  end

  def all_lists
    @session[:lists]
  end

  def create_todo_item list_id, todo_name
    list = find_todo_list list_id
    todos = list[:todos]
    todo_id = next_element_id todos
    todos << { id: todo_id, name: todo_name, completed: false }
  end

  def create_todo_list name
    id = next_id all_lists
    all_lists << { id: id, name: name, todos: [] }
  end

  def delete_list id
    all_lists.reject! { |list| list[:id] == id }
  end

  def delete_todo_item list_id, todo_id
    list = find_todo_list list_id
    list[:todos].reject! { |todo| todo[:id] == todo_id }
  end

  def exists? name
    all_lists.any? { |list| list[:name] == name }
  end

  def find_todo_list id
    all_lists.find { |list| list[:id] == id }
  end

  def mark_all_complete id
    list = find_todo_list id
    list[:todos].each { |todo| todo[:completed] = true }
  end

  def update_list_name id, new_name
    list = find_todo_list id
    list[:name] = new_name
  end

  def mark_todo_status list_id, todo_id, completed
    list = find_todo_list list_id
    todo = list[:todos].find { |this_todo| this_todo[:id] == todo_id }
    todo[:completed] = completed
  end

  private

  # :reek:UtilityFunction
  def next_id elements
    max = elements.map { |todo| todo[:id] }.max || 0
    max + 1
  end
end
