#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for Route class.

require_relative 'test_helpers'

#------------------------------------------------------------------------------

describe File.basename(__FILE__).to_s do
  include TestHelpers

  eval TestHelpers.setup_code # rubocop:disable Eval

  describe with_id 'the tests' do
    it 'generates an add_todo route string' do
      Route.add_todo(5).must_equal '/lists/5/todos'
    end

    it 'generates a complete_all_todos route string' do
      Route.complete_all_todos(5).must_equal '/lists/5/complete_all'
    end

    it 'generates a complete_todo route string' do
      Route.complete_todo(5, 3).must_equal '/lists/5/todos/3'
    end

    it 'generates a create_todo_list route string' do
      Route.create_todo_list.must_equal '/lists/new'
    end

    it 'generates a delete_todo_list route string' do
      Route.delete_todo_list(7).must_equal '/lists/7/destroy'
    end

    it 'generates a delete_todo_item route string' do
      Route.delete_todo_item(7, 12).must_equal '/lists/7/todos/12/destroy'
    end

    it 'generates an edit_todo_list route string' do
      Route.edit_todo_list(12).must_equal '/lists/12/edit'
    end

    it 'generates an index route string' do
      Route.index.must_equal '/'
    end

    it 'generates a view_list route string' do
      Route.view_list(12).must_equal '/lists/12'
    end

    it 'generates a all_lists route string' do
      Route.all_lists.must_equal '/lists'
    end
  end
end
