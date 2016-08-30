#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for 'post /lists/:list_id/todos'.

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

    describe with_id 'create a single todo' do
      before do
        @name = 'Groceries'
        @storage.create_todo_list @name
        post Route.add_todo(1), todo: 'Apples'
        must_redirect_to :list
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'has a success message' do
        session.must_have_success :todo_created, list_name: @name
      end

      describe with_id 'the list' do
        before do
          @todo = selector('.todo').must_have_one
        end

        it 'has an incomplete todo' do
          @todo.must_be_class 'incomplete'
        end

        it 'has a complete todo' do
          @todo.wont_be_class 'complete'
        end

        it 'has a form for toggling the completion status' do
          form = selector('form.mark-todo', @todo).must_have_one
          form.must_be_form 'post', Route.complete_todo(1, 1)
        end

        it 'has a field to mark the completion status correctly' do
          input = selector('form.mark-todo input', @todo).must_have_one
          input.must_be_input type: 'hidden', name: 'completed', value: 'true'
        end

        it 'has a button to toggle the completion status' do
          button = selector('form.mark-todo button', @todo).must_have_one
          button.must_be_button @message.ui(:complete), type: 'submit'
        end

        it 'has the correct todo name' do
          name = selector('h3', @todo).must_have_one
          name.must_be_heading 3, 'Apples'
        end

        it 'has a form to delete the todo' do
          form = selector('form.delete-todo', @todo).must_have_one
          form.must_be_form 'post', Route.delete_todo_item(1, 1)
        end

        it 'has a button to delete the todo' do
          button = selector('form.delete-todo button.delete', @todo).must_have_one
          button.must_be_button @message.ui(:delete), type: 'submit'
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'create multiple todos' do
      before do
        @name = 'Groceries'
        @todo_name = 'Meat'
        @storage.create_todo_list @name
        @storage.create_todo_item 1, 'Apples'
        post Route.add_todo(1), todo: @todo_name
        must_redirect_to :list
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'has a success message' do
        session.must_have_success :todo_created, list_name: @name
      end

      describe with_id 'the list' do
        before do
          todos = selector('.todo').must_have 2
          @todo = todos[1]
        end

        it 'has an incomplete todo' do
          @todo.must_be_class 'incomplete'
        end

        it 'has a complete todo' do
          @todo.wont_be_class 'complete'
        end

        it 'has a form for toggling the completion status' do
          form = selector('form.mark-todo', @todo).must_have_one
          form.must_be_form 'post', Route.complete_todo(1, 2)
        end

        it 'has a field to mark the completion status correctly' do
          input = selector('form.mark-todo input', @todo).must_have_one
          input.must_be_input type: 'hidden', name: 'completed', value: 'true'
        end

        it 'has a button to toggle the completion status' do
          button = selector('form.mark-todo button', @todo).must_have_one
          button.must_be_button @message.ui(:complete), type: 'submit'
        end

        it 'has the correct todo name' do
          name = selector('h3', @todo).must_have_one
          name.must_be_heading 3, @todo_name
        end

        it 'has a form to delete the todo' do
          form = selector('form.delete-todo', @todo).must_have_one
          form.must_be_form 'post', Route.delete_todo_item(1, 2)
        end

        it 'has a button to delete the todo' do
          button = selector('form.delete-todo button.delete', @todo).must_have_one
          button.must_be_button @message.ui(:delete), type: 'submit'
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'create multiple todos with completed todos' do
      before do
        @name = 'Groceries'
        @todo_name = 'Meat'
        @storage.create_todo_list @name
        @storage.create_todo_item 1, 'Apples'
        @storage.mark_todo 1, 1, true
        post Route.add_todo(1), todo: @todo_name
        must_redirect_to :list
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'has a success message' do
        session.must_have_success :todo_created, list_name: @name
      end

      describe with_id 'the list' do
        before do
          todos = selector('.todo').must_have 2
          @todo = todos[0]
        end

        it 'has an incomplete todo' do
          @todo.must_be_class 'incomplete'
        end

        it 'has a complete todo' do
          @todo.wont_be_class 'complete'
        end

        it 'has a form for toggling the completion status' do
          form = selector('form.mark-todo', @todo).must_have_one
          form.must_be_form 'post', Route.complete_todo(1, 2)
        end

        it 'has a field to mark the completion status correctly' do
          input = selector('form.mark-todo input', @todo).must_have_one
          input.must_be_input type: 'hidden', name: 'completed', value: 'true'
        end

        it 'has a button to toggle the completion status' do
          button = selector('form.mark-todo button', @todo).must_have_one
          button.must_be_button @message.ui(:complete), type: 'submit'
        end

        it 'has the correct todo name' do
          name = selector('h3', @todo).must_have_one
          name.must_be_heading 3, @todo_name
        end

        it 'has a form to delete the todo' do
          form = selector('form.delete-todo', @todo).must_have_one
          form.must_be_form 'post', Route.delete_todo_item(1, 2)
        end

        it 'has a button to delete the todo' do
          button = selector('form.delete-todo button.delete', @todo).must_have_one
          button.must_be_button @message.ui(:delete), type: 'submit'
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'add todo to non-existent list' do
      before do
        post Route.add_todo(1), todo: 'Meat'
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

    describe with_id 'create todo with long name' do
      before do
        @name = 'Groceries'
        @storage.create_todo_list @name
        post Route.add_todo(1), todo: 'a' * 100
        must_redirect_to :list
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'does have a success message' do
        session.must_have_success :todo_created, list_name: @name
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'create todo with short name' do
      before do
        @name = 'Groceries'
        @storage.create_todo_list @name
        post Route.add_todo(1), todo: 'a'
        must_redirect_to :list
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'does have a success message' do
        session.must_have_success :todo_created, list_name: @name
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'create todo with empty name' do
      before do
        @storage.create_todo_list 'Groceries'
        post Route.add_todo(1), todo: ''
      end

      it 'shows the correct page' do
        must_load :list
      end

      it 'has an error message' do
        session.must_have_error :todo_name_length
      end

      it 'does not have a success message' do
        session.wont_have_success
      end

      it 'continues to show the supplied name' do
        input = selector('input[name="todo"][type="text"]').must_have_one
        input.must_be_input value: ''
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'create todo with overlong name' do
      before do
        @todo_name = 'a' * 101
        @storage.create_todo_list 'Groceries'
        post Route.add_todo(1), todo: @todo_name
      end

      it 'shows the correct page' do
        must_load :list
      end

      it 'has an error message' do
        session.must_have_error :todo_name_length
      end

      it 'does not have a success message' do
        session.wont_have_success
      end

      it 'continues to show the supplied name' do
        input = selector('input[name="todo"][type="text"]').must_have_one
        input.must_be_input value: @todo_name
      end
    end
  end
end
