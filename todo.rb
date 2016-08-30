#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true

require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'

require_relative 'lib/database_persistence'
require_relative 'lib/helpers'
require_relative 'lib/http_status'
require_relative 'lib/messages'
require_relative 'lib/route'

SECRET_KEY = "Why in the world aren't we doing something else?"

configure do
  enable :sessions
  set :erb, escape_html: true
  set :session_secret, SECRET_KEY
end

# :nocov:
configure :development do
  require 'sinatra/reloader' if development?
  also_reload 'lib/database_persistence.rb'
  also_reload 'lib/helpers.rb'
  also_reload 'lib/http_status.rb'
  also_reload 'lib/route.rb'
  also_reload 'lib/sql.rb'
end
# :nocov:

helpers Helpers

before do
  @storage = DatabasePersistence.new logger: logger
  @message = Messages.new
end

after do
  @storage.finish
end

# Get list_id and list for each route that has a list id parameter
before %r{^/lists/(\d+)} do |id|
  @list_id = id.to_i
  @list = todo_list @list_id

  unless @list
    session_error :no_todos_list
    redirect Route.all_lists
  end
end

# Add a new todo to a todo list
post Route::ADD_TODO do
  success = @message.success :todo_created, list_name: @list[:name]
  handlers = make_handlers Route.view_list(@list_id), success, :list

  post_handler handlers do
    @todo_name = params[:todo].strip

    error = validate_todo_name @todo_name
    next error if error

    @storage.create_todo_item @list_id, @todo_name
    @storage.error_message
  end
end

# View list of all todo lists
get Route::ALL_LISTS do
  load_erb :lists
end

# Mark all todos for a list as complete
post Route::COMPLETE_ALL_TODOS do
  success = @message.success :todos_completed, list_name: @list[:name]
  handlers = make_handlers Route.view_list(@list_id), success, :list

  post_handler handlers do
    @storage.mark_all_complete @list_id
    @storage.error_message
  end
end

# Render the new todo list form
get Route::CREATE_LIST do
  load_erb :new_list
end

# Create a new todo list
post Route::CREATE_LIST do
  handlers = make_handlers Route.all_lists, :list_created, :new_list

  post_handler handlers do
    @list_name = params[:list_name].strip
    error = validate_list_name @list_name
    next error if error

    @storage.create_todo_list @list_name
    @storage.error_message
  end
end

# Delete a todo list by id
post Route::DELETE_LIST do
  handlers = make_handlers Route.all_lists, :list_deleted, :edit_list

  post_handler handlers, ajax: Route.all_lists do
    @storage.delete_todo_list @list_id
    @storage.error_message
  end
end

# Delete a todo from a todo list
post Route::DELETE_TODO do
  success = @message.success :todo_deleted, list_name: @list[:name]
  handlers = make_handlers back, success, :list

  post_handler handlers do
    @storage.delete_todo_item @list_id, params[:id].to_i
    @storage.error_message
  end
end

# Edit an existing todo list
get Route::EDIT_LIST_FORM do
  load_erb :edit_list
end

# Main page is the all lists page
get Route::INDEX do
  redirect Route.all_lists
end

# Update an existing todo list's name
post Route::UPDATE_LIST_NAME do
  handlers = make_handlers Route.view_list(@list_id), :list_updated, :new_list

  post_handler handlers do
    @list_name = params[:list_name].strip
    error = validate_list_name @list_name
    next error if error

    @storage.update_list_name @list_id, @list_name
    @storage.error_message
  end
end

# Update the status of a todo
post Route::UPDATE_TODO_STATUS do
  handlers = make_handlers Route.view_list(@list_id), :todo_updated, :list

  post_handler handlers do
    is_completed = params[:completed] == 'true'
    @storage.mark_todo @list_id, params[:id].to_i, is_completed
    @storage.error_message
  end
end

# View a single todo list
get Route::VIEW_LIST do
  load_erb :list
end

#------------------------------------------------------------------------------
# Miscellaneous local helpers

AJAX_ENV = 'HTTP_X_REQUESTED_WITH'
AJAX_VALUE = 'XMLHttpRequest'

def ajax_env
  { AJAX_ENV => AJAX_VALUE }
end

def ajax_request?
  env[AJAX_ENV] == AJAX_VALUE
end

def data_path
  path = Pathname(__FILE__) + '..' + 'data'
  path.to_path
end

def load_erb name
  @page = name.to_sym
  layout = request.xhr? ? false : :layout

  erb name, layout: layout
end

def make_handlers route, message, error
  { success: on_success(route, message), error: on_error(error) }
end

# :reek:UtilityFunction
def name_size_valid? name
  (1..100).cover? name.size
end

def on_error load_page
  lambda do |message|
    session_error message
    load_erb load_page
  end
end

def on_success target_route, message
  lambda do
    session_success message
    redirect target_route
  end
end

def post_handler handlers, ajax: nil
  error = yield
  if error
    handlers[:error].call error
  elsif ajax_request?
    ajax ? ajax : status(HTTPStatus::NO_CONTENT)
  else
    handlers[:success].call
  end
end

def session_error message
  session[:error] = @message.error(message) || message if message
end

def session_success message
  session[:success] = @message.success(message) || message if message
end

# Return error message if name is invalid. Returns error message or nil.
def validate_list_name name
  :list_name_length unless name_size_valid? name
end

# Return error message if name is invalid. Returns error message or nil.
def validate_todo_name name
  :todo_name_length unless name_size_valid? name
end
