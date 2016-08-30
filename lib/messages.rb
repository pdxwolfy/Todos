#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true

# Message storage structure with automatic substitution
class Messages
  module MessageStrings
    MESSAGES = {
      error:   {
        list_name_length: 'List name must be between 1 and 100 characters.',
        list_name_unique: 'List name must be unique.',
        no_todo:          'No such todo.',
        no_todos_list:    'No such todo list.',
        todo_name_length: 'Todo name must be between 1 and 100 characters.'
      },

      success: {
        list_created:    'The list has been created.',
        list_deleted:    'The list has been deleted.',
        list_updated:    'The list has been updated.',
        todo_created:    'The todo has been created and added to %{list_name}.',
        todo_deleted:    'The todo has been deleted from %{list_name}.',
        todo_updated:    'The todo status has been updated.',
        todos_completed: 'All todos have been completed for %{list_name}.'
      },

      ui:      {
        add:                 'Add',
        all_lists:           'All Lists',
        app_name:            'Todo Tracker',
        app_title:           'Todo Tracker',
        cancel:              'Cancel',
        complete:            'Complete',
        complete_all:        'Complete All',
        delete:              'Delete',
        delete_list:         'Delete List',
        edit_list:           'Edit List',
        editing_list:        'Editing %{name}',
        enter_list_name:     'Enter the name for your new list:',
        enter_new_list_name: 'Enter the new name for the list:',
        enter_todo_name:     'Enter a new todo item:',
        list_name:           'List Name',
        new_list:            'New List',
        save:                'Save',
        something_todo:      'Something to do'
      }
    }.freeze
  end.freeze

  # :reek:DataClump: { exclude: [:error, :success, :ui] }
  def error message_id, **other_variables
    fetch :error, message_id, other_variables
  end

  def success message_id, **other_variables
    fetch :success, message_id, other_variables
  end

  def ui message_id, **other_variables
    fetch :ui, message_id, other_variables
  end

  private

  def fetch category, message_id, other_variables
    message = MessageStrings::MESSAGES[category].fetch message_id, message_id
    format message, other_variables
  end
end
