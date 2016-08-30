#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for 'post /lists/:list_id/complete_all'.

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

    describe with_id 'mark all todos' do
      before do
        @name = 'Groceries'
        @storage.create_todo_list @name
        @storage.create_todo_item 1, 'Milk'
        @storage.create_todo_item 1, 'Eggs'
        post Route.complete_all_todos(1)
        must_redirect_to :list
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'has a success message' do
        session.must_have_success :todos_completed, list_name: @name
      end

      it 'is marked complete' do
        selector('.todo-list.complete').must_have_one
      end

      it 'is not marked incomplete' do
        selector('.todo-list.incomplete').must_be_empty
      end

      it 'does not have a complete-all form' do
        selector('form#complete-all').must_be_empty
      end

      #------------------------------------------------------------------------

      describe with_id 'first todo on list' do
        before do
          todos = selector('.todo').must_have 2
          @todo = todos[0]
        end

        it 'is eggs' do
          item = selector('h3', @todo).must_have_one
          item.must_be_heading 3, 'Eggs'
        end

        it 'is complete' do
          @todo.must_be_class 'complete'
        end

        it 'is not incomplete' do
          @todo.wont_be_class 'incomplete'
        end
      end

      #------------------------------------------------------------------------

      describe with_id 'second todo on list' do
        before do
          todos = selector('.todo').must_have 2
          @todo = todos[1]
        end

        it 'is milk' do
          item = selector('h3', @todo).must_have_one
          item.must_be_heading 3, 'Milk'
        end

        it 'is complete' do
          @todo.must_be_class 'complete'
        end

        it 'is not incomplete' do
          @todo.wont_be_class 'incomplete'
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'update todo on non-existent list' do
      before do
        post Route.complete_all_todos(1)
        must_redirect_to :lists
      end

      it 'has an error message' do
        session.must_have_error :no_todos_list
      end

      it 'does not have a success message' do
        session.wont_have_success
      end
    end
  end
end
