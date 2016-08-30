#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for 'post /lists/:list_id/edit'.

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

    describe with_id 'rename a list' do
      before do
        @name = 'Groceries'
        @new_name = 'Shopping'
        @storage.create_todo_list @name
        @storage.create_todo_item 1, 'Milk'
        @storage.create_todo_item 1, 'Eggs'
        post Route.update_list_name(1), list_name: @new_name
        must_redirect_to :list
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'has a success message' do
        session.must_have_success :list_updated
      end

      it 'shows the proper list name' do
        heading = selector('h2').must_have_one
        heading.must_be_heading 2, @new_name
      end

      describe with_id 'todo items' do
        before do
          @todos = selector('.todo').must_have 2
        end

        it 'has Milk' do
          heading = selector('h3', @todos[0]).must_have_one
          heading.must_be_heading 3, 'Eggs'
        end

        it 'has Eggs' do
          heading = selector('h3', @todos[1]).must_have_one
          heading.must_be_heading 3, 'Milk'
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'update non-existent list' do
      before do
        post Route.update_list_name(1), list_name: 'Xyzzy'
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

    describe with_id 'rename list with long name' do
      before do
        @name = 'Shopping'
        @new_name = 'a' * 100
        @storage.create_todo_list @name
        @storage.create_todo_item 1, 'Milk'
        post Route.update_list_name(1), list_name: @new_name
        must_redirect_to :list
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'does have a success message' do
        session.must_have_success :list_updated
      end

      it 'has the correct title' do
        title = selector('.todo-list h2').must_have_one
        title.must_be_heading 2, @new_name
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'create list with short name' do
      before do
        @name = 'Shopping'
        @new_name = 'a'
        @storage.create_todo_list @name
        @storage.create_todo_item 1, 'Milk'
        post Route.update_list_name(1), list_name: @new_name
        must_redirect_to :list
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'does have a success message' do
        session.must_have_success :list_updated
      end

      it 'has the correct title' do
        title = selector('.todo-list h2').must_have_one
        title.must_be_heading 2, @new_name
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'rename list with empty name' do
      before do
        @name = 'Shopping'
        @new_name = ''
        @storage.create_todo_list @name
        @storage.create_todo_item 1, 'Milk'
        post Route.update_list_name(1), list_name: @new_name
      end

      it 'shows the correct page' do
        must_load :new_list
      end

      it 'has an error message' do
        session.must_have_error :list_name_length
      end

      it 'does not have a success message' do
        session.wont_have_success
      end

      it 'has an input box for the list name' do
        input = selector('input[name="list_name"][type="text"]').must_have_one
        placeholder = @message.ui :list_name
        input.must_be_input value: @new_name, placeholder: placeholder
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'rename list with overly long name' do
      before do
        @name = 'Shopping'
        @new_name = 'a' * 101
        @storage.create_todo_list @name
        @storage.create_todo_item 1, 'Milk'
        post Route.update_list_name(1), list_name: @new_name
      end

      it 'shows the correct page' do
        must_load :new_list
      end

      it 'has an error message' do
        session.must_have_error :list_name_length
      end

      it 'does not have a success message' do
        session.wont_have_success
      end

      it 'has an input box for the list name' do
        input = selector('input[name="list_name"][type="text"]').must_have_one
        placeholder = @message.ui :list_name
        input.must_be_input value: @new_name, placeholder: placeholder
      end
    end
  end
end
