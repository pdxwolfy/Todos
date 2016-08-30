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

    describe with_id 'creating a list' do
      before do
        get Route.create_todo_list
      end

      it 'shows the correct page' do
        must_load :new_list
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'does not have a success message' do
        session.wont_have_success
      end

      it 'has a form to create the list' do
        form = selector('form').must_have_one
        form.must_be_form 'post', Route.create_todo_list
      end

      it 'has a prompt to enter the list name' do
        prompt = selector('label[for="list_name"]').must_have_one
        prompt.must_be_label @message.ui(:enter_list_name)
      end

      it 'has an input box for the list name' do
        input = selector('input[name="list_name"][type="text"]').must_have_one
        input.must_be_input value: '', placeholder: @message.ui(:list_name)
      end

      it 'has a Save button' do
        button = selector('input[type="submit"]').must_have_one
        button.must_be_input value: @message.ui(:save)
      end

      it 'has a Cancel button' do
        button = selector('a.cancel').must_have_one
        button.must_be_link Route.all_lists, @message.ui(:cancel)
      end
    end
  end
end
