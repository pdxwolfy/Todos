#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for '/lists/:id'.

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

    describe with_id 'no todos' do
      before do
        get Route.view_list(1)
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

    describe with_id 'no such todo list' do
      before do
        @storage.create_todo_list 'Bucket'
        get Route.view_list(2)
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

    describe with_id 'with todo lists' do
      before do
        @storage.create_todo_list 'Bucket'         # list_id == 1

        @storage.create_todo_list 'Groceries I'    # list_id == 2
        @storage.create_todo_item 2, 'Meat'        # todo_id == 1

        @storage.create_todo_list 'Groceries II'   # list_id == 3
        @storage.create_todo_item 3, 'Meat'        # todo_id == 2
        @storage.mark_todo 3, 2, true

        @storage.create_todo_list 'Homework I'     # list_id == 4
        @storage.create_todo_item 4, 'Math'        # todo_id == 3
        @storage.create_todo_item 4, 'Ruby'        # todo_id == 4

        @storage.create_todo_list 'Homework II'    # list_id == 5
        @storage.create_todo_item 5, 'Math'        # todo_id == 5
        @storage.create_todo_item 5, 'Ruby'        # todo_id == 6
        @storage.mark_todo 5, 5, true

        @storage.create_todo_list 'Homework III'   # list_id == 6
        @storage.create_todo_item 6, 'Math'        # todo_id == 7
        @storage.create_todo_item 6, 'Ruby'        # todo_id == 8
        @storage.mark_todo 6, 8, true

        @storage.create_todo_list 'Homework IV'    # list_id == 7
        @storage.create_todo_item 7, 'Math'        # todo_id == 9
        @storage.create_todo_item 7, 'Ruby'        # todo_id == 10
        @storage.mark_all_complete 7
      end

      (1..7).each do |list_id|
        describe with_id "for list #{list_id}" do
          before do
            get Route.view_list(list_id)
          end

          it 'shows the correct page' do
            must_load :list
          end

          it 'does not have an error message' do
            session.wont_have_error
          end

          it 'does not have a success message' do
            session.wont_have_success
          end

          it 'has a view all lists button' do
            button = selector('a.list').must_have_one
            button.must_be_link Route.all_lists, @message.ui(:all_lists)
          end

          it 'has a #todos section' do
            selector('section#todos').must_have_one
          end

          it 'has a .todo-list section' do
            selector('section.todo-list').must_have_one
          end

          it 'has an edit button' do
            link = selector('a.edit').must_have_one
            link.must_be_link Route.edit_todo_list(list_id),
                              @message.ui(:edit_list)
          end

          it 'has a new-todo form' do
            form = selector('form#new-todo').must_have_one
            form.must_be_form 'post', Route.add_todo(list_id)
          end

          it 'has a prompt for the todo name' do
            prompt = selector('label[for="todo"]').must_have_one
            prompt.must_be_label @message.ui(:enter_todo_name)
          end

          it 'has an input field for the todo name' do
            field = selector('input[name="todo"][type="text"]').must_have_one
            field.must_be_input value:       '',
                                placeholder: @message.ui(:something_todo)
          end

          it 'has an Add button' do
            button = selector('form#new-todo input[type="submit"]').must_have_one
            button.must_be_input value: @message.ui(:add)
          end
        end
      end

      describe with_id 'unique stuff for list 1' do
        before do
          get Route.view_list(1)
        end

        it 'has the correct list name' do
          header = selector('header h2').must_have_one
          header.must_be_heading 2, 'Bucket'
        end

        it 'is marked as incomplete' do
          selector('section.incomplete').must_have_one
        end

        it 'is not marked as complete' do
          selector('section.complete').must_be_empty
        end

        it 'has a complete-all form' do
          form = selector('form#complete-all').must_have_one
          form.must_be_form 'post', Route.complete_all_todos(1)
        end

        it 'has a complete all button in the complete-all form' do
          form = selector('form#complete-all').must_have_one
          button = selector('button[type="submit"].check', form).must_have_one
          button.must_be_button @message.ui(:complete_all)
        end

        it 'has no todos' do
          selector('.todo').must_be_empty
        end
      end

      describe with_id 'unique stuff for list 2' do
        before do
          get Route.view_list(2)
        end

        it 'has the correct list name' do
          header = selector('header h2').must_have_one
          header.must_be_heading 2, 'Groceries I'
        end

        it 'is marked as incomplete' do
          selector('section.incomplete').must_have_one
        end

        it 'is not marked as complete' do
          selector('section.complete').must_be_empty
        end

        it 'has a complete-all form' do
          form = selector('form#complete-all').must_have_one
          form.must_be_form 'post', Route.complete_all_todos(2)
        end

        it 'has a complete all button in the complete-all form' do
          form = selector('form#complete-all').must_have_one
          button = selector('button[type="submit"].check', form).must_have_one
          button.must_be_button @message.ui(:complete_all)
        end

        it 'has one todo' do
          selector('.todo').must_have_one
        end

        it 'has all todos marked incomplete' do
          todo = selector('.todo').must_have_one
          todo.must_be_class 'incomplete'
        end

        it 'has a form for toggling the completion status' do
          form = selector('form.mark-todo').must_have_one
          form.must_be_form 'post', Route.complete_todo(2, 1)
        end

        it 'will mark the completion status correctly' do
          input = selector('form.mark-todo input').must_have_one
          input.must_be_input type: 'hidden', name: 'completed', value: 'true'
        end

        it 'has a button for toggling the completion status' do
          button = selector('form.mark-todo button').must_have_one
          button.must_be_button @message.ui(:complete), type: 'submit'
        end

        it 'has the correct todo name' do
          name = selector('.todo h3').must_have_one
          name.must_be_heading 3, 'Meat'
        end

        it 'has a form for deleting the todo' do
          form = selector('form.delete-todo').must_have_one
          form.must_be_form 'post', Route.delete_todo_item(2, 1)
        end

        it 'has a button for deleting the todo' do
          button = selector('form.delete-todo button.delete').must_have_one
          button.must_be_button @message.ui(:delete), type: 'submit'
        end
      end

      describe with_id 'unique stuff for list 3' do
        before do
          get Route.view_list(3)
        end

        it 'has the correct list name' do
          header = selector('header h2').must_have_one
          header.must_be_heading 2, 'Groceries II'
        end

        it 'is marked as incomplete' do
          selector('section.incomplete').must_be_empty
        end

        it 'is not marked as complete' do
          selector('section.complete').must_have_one
        end

        it 'does not have a complete-all form' do
          selector('form#complete-all').must_be_empty
        end

        it 'has one todo' do
          selector('.todo').must_have_one
        end

        it 'has all todos marked complete' do
          todo = selector('.todo').must_have_one
          todo.must_be_class 'complete'
        end

        it 'has a form for toggling the completion status' do
          form = selector('form.mark-todo').must_have_one
          form.must_be_form 'post', Route.complete_todo(3, 2)
        end

        it 'will mark the completion status correctly' do
          input = selector('form.mark-todo input').must_have_one
          input.must_be_input type: 'hidden', name: 'completed', value: 'false'
        end

        it 'has a button for toggling the completion status' do
          button = selector('form.mark-todo button').must_have_one
          button.must_be_button @message.ui(:complete), type: 'submit'
        end

        it 'has the correct todo name' do
          name = selector('.todo h3').must_have_one
          name.must_be_heading 3, 'Meat'
        end

        it 'has a form for deleting the todo' do
          form = selector('form.delete-todo').must_have_one
          form.must_be_form 'post', Route.delete_todo_item(3, 2)
        end

        it 'has a button for deleting the todo' do
          button = selector('form.delete-todo button.delete').must_have_one
          button.must_be_button @message.ui(:delete), type: 'submit'
        end
      end

      describe with_id 'unique stuff for list 4' do
        before do
          get Route.view_list(4)
        end

        it 'has the correct list name' do
          header = selector('header h2').must_have_one
          header.must_be_heading 2, 'Homework I'
        end

        it 'is marked as incomplete' do
          selector('section.incomplete').must_have_one
        end

        it 'is not marked as complete' do
          selector('section.complete').must_be_empty
        end

        it 'has a complete-all form' do
          form = selector('form#complete-all').must_have_one
          form.must_be_form 'post', Route.complete_all_todos(4)
        end

        it 'has a complete all button in the complete-all form' do
          form = selector('form#complete-all').must_have_one
          button = selector('button[type="submit"].check', form).must_have_one
          button.must_be_button @message.ui(:complete_all)
        end

        it 'has two todos' do
          selector('.todo').must_have 2
        end

        it 'has all todos marked incomplete' do
          todos = selector('.todo').must_have 2
          todos[0].must_be_class 'incomplete'
          todos[1].must_be_class 'incomplete'
        end

        it 'has a form for toggling the completion status' do
          forms = selector('form.mark-todo').must_have 2
          forms[0].must_be_form 'post', Route.complete_todo(4, 3)
          forms[1].must_be_form 'post', Route.complete_todo(4, 4)
        end

        it 'will mark the completion status correctly' do
          inputs = selector('form.mark-todo input').must_have 2
          inputs[0].must_be_input type:  'hidden',
                                  name:  'completed',
                                  value: 'true'
          inputs[1].must_be_input type:  'hidden',
                                  name:  'completed',
                                  value: 'true'
        end

        it 'has a button for toggling the completion status' do
          buttons = selector('form.mark-todo button').must_have 2
          buttons[0].must_be_button @message.ui(:complete), type: 'submit'
          buttons[1].must_be_button @message.ui(:complete), type: 'submit'
        end

        it 'has the correct todo name' do
          names = selector('.todo h3').must_have 2
          names[0].must_be_heading 3, 'Math'
          names[1].must_be_heading 3, 'Ruby'
        end

        it 'has a form for deleting the todo' do
          forms = selector('form.delete-todo').must_have 2
          forms[0].must_be_form 'post', Route.delete_todo_item(4, 3)
          forms[1].must_be_form 'post', Route.delete_todo_item(4, 4)
        end

        it 'has a button for deleting the todo' do
          buttons = selector('form.delete-todo button.delete').must_have 2
          buttons[0].must_be_button @message.ui(:delete), type: 'submit'
          buttons[1].must_be_button @message.ui(:delete), type: 'submit'
        end
      end

      describe with_id 'unique stuff for list 5' do
        before do
          get Route.view_list(5)
        end

        it 'has the correct list name' do
          header = selector('header h2').must_have_one
          header.must_be_heading 2, 'Homework II'
        end

        it 'is marked as incomplete' do
          selector('section.incomplete').must_have_one
        end

        it 'is not marked as complete' do
          selector('section.complete').must_be_empty
        end

        it 'has a complete-all form' do
          form = selector('form#complete-all').must_have_one
          form.must_be_form 'post', Route.complete_all_todos(5)
        end

        it 'has a complete all button in the complete-all form' do
          form = selector('form#complete-all').must_have_one
          button = selector('button[type="submit"].check', form).must_have_one
          button.must_be_button @message.ui(:complete_all)
        end

        it 'has two todos' do
          selector('.todo').must_have 2
        end

        it 'has first todo marked as incomplete, second as complete' do
          todos = selector('.todo').must_have 2
          todos[0].must_be_class 'incomplete'
          todos[1].must_be_class 'complete'
        end

        it 'has a form for toggling the completion status' do
          forms = selector('form.mark-todo').must_have 2
          forms[0].must_be_form 'post', Route.complete_todo(5, 6)
          forms[1].must_be_form 'post', Route.complete_todo(5, 5)
        end

        it 'will mark the completion status correctly' do
          inputs = selector('form.mark-todo input').must_have 2
          inputs[0].must_be_input type:  'hidden',
                                  name:  'completed',
                                  value: 'true'
          inputs[1].must_be_input type:  'hidden',
                                  name:  'completed',
                                  value: 'false'
        end

        it 'has a button for toggling the completion status' do
          buttons = selector('form.mark-todo button').must_have 2
          buttons[0].must_be_button @message.ui(:complete), type: 'submit'
          buttons[1].must_be_button @message.ui(:complete), type: 'submit'
        end

        it 'has the correct todo name' do
          names = selector('.todo h3').must_have 2
          names[0].must_be_heading 3, 'Ruby'
          names[1].must_be_heading 3, 'Math'
        end

        it 'has a form for deleting the todo' do
          forms = selector('form.delete-todo').must_have 2
          forms[0].must_be_form 'post', Route.delete_todo_item(5, 6)
          forms[1].must_be_form 'post', Route.delete_todo_item(5, 5)
        end

        it 'has a button for deleting the todo' do
          buttons = selector('form.delete-todo button.delete').must_have 2
          buttons[0].must_be_button @message.ui(:delete), type: 'submit'
          buttons[1].must_be_button @message.ui(:delete), type: 'submit'
        end
      end

      describe with_id 'unique stuff for list 6' do
        before do
          get Route.view_list(6)
        end

        it 'has the correct list name' do
          header = selector('header h2').must_have_one
          header.must_be_heading 2, 'Homework III'
        end

        it 'is marked as incomplete' do
          selector('section.incomplete').must_have_one
        end

        it 'is not marked as complete' do
          selector('section.complete').must_be_empty
        end

        it 'has a complete-all form' do
          form = selector('form#complete-all').must_have_one
          form.must_be_form 'post', Route.complete_all_todos(6)
        end

        it 'has a complete all button in the complete-all form' do
          form = selector('form#complete-all').must_have_one
          button = selector('button[type="submit"].check', form).must_have_one
          button.must_be_button @message.ui(:complete_all)
        end

        it 'has two todos' do
          selector('.todo').must_have 2
        end

        it 'has first todo marked as incomplete, second as complete' do
          todos = selector('.todo').must_have 2
          todos[0].must_be_class 'incomplete'
          todos[1].must_be_class 'complete'
        end

        it 'has a form for toggling the completion status' do
          forms = selector('form.mark-todo').must_have 2
          forms[0].must_be_form 'post', Route.complete_todo(6, 7)
          forms[1].must_be_form 'post', Route.complete_todo(6, 8)
        end

        it 'will mark the completion status correctly' do
          inputs = selector('form.mark-todo input').must_have 2
          inputs[0].must_be_input type:  'hidden',
                                  name:  'completed',
                                  value: 'true'
          inputs[1].must_be_input type:  'hidden',
                                  name:  'completed',
                                  value: 'false'
        end

        it 'has a button for toggling the completion status' do
          buttons = selector('form.mark-todo button').must_have 2
          buttons[0].must_be_button @message.ui(:complete), type: 'submit'
          buttons[1].must_be_button @message.ui(:complete), type: 'submit'
        end

        it 'has the correct todo name' do
          names = selector('.todo h3').must_have 2
          names[0].must_be_heading 3, 'Math'
          names[1].must_be_heading 3, 'Ruby'
        end

        it 'has a form for deleting the todo' do
          forms = selector('form.delete-todo').must_have 2
          forms[0].must_be_form 'post', Route.delete_todo_item(6, 7)
          forms[1].must_be_form 'post', Route.delete_todo_item(6, 8)
        end

        it 'has a button for deleting the todo' do
          buttons = selector('form.delete-todo button.delete').must_have 2
          buttons[0].must_be_button @message.ui(:delete), type: 'submit'
          buttons[1].must_be_button @message.ui(:delete), type: 'submit'
        end
      end

      describe with_id 'unique stuff for list 7' do
        before do
          get Route.view_list(7)
        end

        it 'has the correct list name' do
          header = selector('header h2').must_have_one
          header.must_be_heading 2, 'Homework IV'
        end

        it 'is marked as complete' do
          selector('section.complete').must_have_one
        end

        it 'is not marked as incomplete' do
          selector('section.incomplete').must_be_empty
        end

        it 'does not have a complete-all form' do
          selector('form#complete-all').must_be_empty
        end

        it 'has two todos' do
          selector('.todo').must_have 2
        end

        it 'has both todos marked as complete' do
          todos = selector('.todo').must_have 2
          todos[0].must_be_class 'complete'
          todos[1].must_be_class 'complete'
        end

        it 'has a form for toggling the completion status' do
          forms = selector('form.mark-todo').must_have 2
          forms[0].must_be_form 'post', Route.complete_todo(7, 9)
          forms[1].must_be_form 'post', Route.complete_todo(7, 10)
        end

        it 'will mark the completion status correctly' do
          inputs = selector('form.mark-todo input').must_have 2
          inputs[0].must_be_input type:  'hidden',
                                  name:  'completed',
                                  value: 'false'
          inputs[1].must_be_input type:  'hidden',
                                  name:  'completed',
                                  value: 'false'
        end

        it 'has a button for toggling the completion status' do
          buttons = selector('form.mark-todo button').must_have 2
          buttons[0].must_be_button @message.ui(:complete), type: 'submit'
          buttons[1].must_be_button @message.ui(:complete), type: 'submit'
        end

        it 'has the correct todo name' do
          names = selector('.todo h3').must_have 2
          names[0].must_be_heading 3, 'Math'
          names[1].must_be_heading 3, 'Ruby'
        end

        it 'has a form for deleting the todo' do
          forms = selector('form.delete-todo').must_have 2
          forms[0].must_be_form 'post', Route.delete_todo_item(7, 9)
          forms[1].must_be_form 'post', Route.delete_todo_item(7, 10)
        end

        it 'has a button for deleting the todo' do
          buttons = selector('form.delete-todo button.delete').must_have 2
          buttons[0].must_be_button @message.ui(:delete), type: 'submit'
          buttons[1].must_be_button @message.ui(:delete), type: 'submit'
        end
      end
    end
  end
end
