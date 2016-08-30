#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for 'post /lists/:list_id/todos/:id/destroy'.

require_relative 'test_helpers'

#------------------------------------------------------------------------------

describe File.basename(__FILE__).to_s do
  include TestHelpers

  setup = File.read((Pathname(__FILE__) + '..' + 'test_setup.rb').to_s)
  eval setup # rubocop:disable Eval

  describe with_id 'create database' do
    before do
      @storage = DatabasePersistence.new
    end

    after do
      @storage.finish
    end

    #--------------------------------------------------------------------------

    describe with_id 'delete individual todos' do
      before do
        @name = 'Groceries'
        @storage.create_todo_list @name
        @storage.create_todo_item 1, 'Milk'
        @storage.create_todo_item 1, 'Eggs'
        post Route.delete_todo_item(1, 1), {},
             'HTTP_REFERER' => Route.view_list(1)
        must_redirect_to :list
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'has a success message' do
        session.must_have_success :todo_deleted, list_name: @name
      end

      it 'is marked incomplete' do
        selector('.todo-list.incomplete').must_have_one
      end

      it 'is not marked complete' do
        selector('.todo-list.complete').must_be_empty
      end

      #------------------------------------------------------------------------

      describe with_id 'remaining todo' do
        before do
          @todo = selector('.todo').must_have_one
        end

        it 'is eggs' do
          item = selector('h3', @todo).must_have_one
          item.must_be_heading 3, 'Eggs'
        end

        it 'is incomplete' do
          @todo.must_be_class 'incomplete'
        end

        it 'is not complete' do
          @todo.wont_be_class 'complete'
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'delete todo with Ajax' do
      before do
        @name = 'Groceries'
        @storage.create_todo_list @name
        @storage.create_todo_item 1, 'Milk'
        @storage.create_todo_item 1, 'Eggs'
        post Route.delete_todo_item(1, 1),
             {},
             ajax_env.merge('HTTP_REFERER' => Route.view_list(1))
      end

      it 'must be Ajax response' do
        must_be_ajax_response
      end

      it 'must delete the todo' do
        todos = @storage.find_todo_items 1
        todos.size.must_equal 1
        todos.first[:id].must_equal 2
        todos.first[:name].must_equal 'Eggs'
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'delete todo from non-existent list' do
      before do
        post Route.delete_todo_item(1, 1)
        must_redirect_to :lists
      end

      it 'has an error message' do
        session.must_have_error :no_todos_list
      end

      it 'does not have a success message' do
        session.wont_have_success
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'delete non-existent todo' do
      before do
        @storage.create_todo_list 'Groceries'
        post Route.complete_todo(1, 1), completed: 'true'
      end

      it 'loads the correct page' do
        must_load :list
      end

      it 'has an error message' do
        session.must_have_error :no_todo
      end

      it 'does not have a success message' do
        session.wont_have_success
      end
    end
  end
end
