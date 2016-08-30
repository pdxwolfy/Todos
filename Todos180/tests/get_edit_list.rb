#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for 'get /lists/:id/edit'.

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

    describe with_id 'no lists to edit' do
      before do
        get Route.edit_todo_list(1)
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
        get Route.edit_todo_list(2)
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

    describe with_id 'the list exists' do
      before do
        @storage.create_todo_list 'Bucket'
        get Route.edit_todo_list(1)
      end

      it 'shows the correct page' do
        must_load :edit_list
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'does not have a success message' do
        session.wont_have_success
      end

      it 'has a todos section' do
        selector('section#todos').must_have_one
      end

      it 'has a valid heading' do
        heading = selector('h2').must_have_one
        heading.must_be_heading 2, @message.ui(:editing_list, name: 'Bucket')
      end

      it 'has a delete form' do
        form = selector('form.delete').must_have_one
        form.must_be_form 'post', Route.delete_todo_list(1)
      end

      it 'has a delete button in the delete form' do
        form = selector('form.delete').must_have_one
        button = selector('button[type="submit"].delete', form).must_have_one
        button.must_be_button @message.ui(:delete_list)
      end

      it 'has a new list name form' do
        form = selector('form#edit').must_have_one
        form.must_be_form 'post', Route.update_list_name(1)
      end

      it 'has a prompt for the new list name' do
        prompt = selector('label[for="list_name"]').must_have_one
        prompt.must_be_label @message.ui(:enter_new_list_name)
      end

      it 'has an input field for the updated todo name' do
        field = selector('input[name="list_name"][type="text"]').must_have_one
        field.must_be_input value:       'Bucket',
                            placeholder: @message.ui(:list_name)
      end

      it 'has a Save button' do
        button = selector('form#edit input[type="submit"]').must_have_one
        button.must_be_input value: @message.ui(:save)
      end

      it 'has a Cancel button' do
        button = selector('form#edit a.cancel').must_have_one
        button.must_be_link Route.view_list(1), @message.ui(:cancel)
      end
    end
  end
end
