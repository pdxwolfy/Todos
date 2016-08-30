#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true

# Provides constants and some methods for working with routes
module Route
  INDEX              = '/'                                    # get
  ALL_LISTS          = '/lists'                               # get
  CREATE_LIST        = '/lists/new'                           # get/post
  VIEW_LIST          = '/lists/:id'                           # get
  COMPLETE_ALL_TODOS = '/lists/:id/complete_all'              # post
  DELETE_LIST        = '/lists/:id/destroy'                   # post
  EDIT_LIST_FORM     = '/lists/:id/edit'                      # get
  UPDATE_LIST_NAME   = '/lists/:id/edit'                      # post
  ADD_TODO           = '/lists/:list_id/todos'                # post
  UPDATE_TODO_STATUS = '/lists/:list_id/todos/:id'            # post
  DELETE_TODO        = '/lists/:list_id/todos/:id/destroy'    # post

  # Route groupings
  INDEX_AND_FILE = %r{(?:\A / \z) | (?:\A /file (?:/.*)? \z)}x

  def self.add_todo list_id
    interpolate ADD_TODO, list_id: list_id
  end

  def self.all_lists
    ALL_LISTS
  end

  def self.complete_all_todos list_id
    interpolate COMPLETE_ALL_TODOS, id: list_id
  end

  def self.complete_todo list_id, todo_id
    interpolate UPDATE_TODO_STATUS, list_id: list_id, id: todo_id
  end

  def self.create_todo_list
    CREATE_LIST
  end

  def self.delete_todo_item list_id, todo_id
    interpolate DELETE_TODO, list_id: list_id, id: todo_id
  end

  def self.delete_todo_list list_id
    interpolate DELETE_LIST, id: list_id
  end

  def self.edit_todo_list list_id
    interpolate EDIT_LIST_FORM, id: list_id
  end

  def self.index
    INDEX
  end

  def self.update_list_name list_id
    interpolate UPDATE_LIST_NAME, id: list_id
  end

  def self.view_list list_id
    interpolate VIEW_LIST, id: list_id
  end

  class << self
    private

    def interpolate route, variables
      variables.each_pair do |parameter, value|
        route = route.sub ':' + parameter.to_s, value.to_s
      end
      route
    end
  end
end
