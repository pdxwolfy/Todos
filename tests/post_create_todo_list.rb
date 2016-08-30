#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for 'post /lists/new'.

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

    describe with_id 'create a single list' do
      before do
        post Route.create_todo_list, list_name: 'Bucket'
        must_redirect_to :lists
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'does have a success message' do
        session.must_have_success :list_created
      end

      describe with_id 'the list' do
        before do
          @list = selector('.todo-list').must_have_one
        end

        it 'is an incomplete list' do
          @list.must_be_class 'incomplete'
        end

        it 'has a link to the correct view page' do
          link = selector('a', @list).must_have_one
          link.must_be_link Route.view_list(1)
        end

        it 'has the correct title' do
          title = selector('h2', @list).must_have_one
          title.must_be_heading 2, 'Bucket'
        end

        it 'has the correct counts' do
          counts = selector('p', @list).must_have_one
          counts.must_be_p '0 / 0'
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'create list with long name' do
      before do
        @name = 'a' * 100
        post Route.create_todo_list, list_name: @name
        must_redirect_to :lists
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'does have a success message' do
        session.must_have_success :list_created
      end

      it 'has the correct title' do
        title = selector('.todo-list h2').must_have_one
        title.must_be_heading 2, @name
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'create list with short name' do
      before do
        @name = 'a'
        post Route.create_todo_list, list_name: @name
        must_redirect_to :lists
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'does have a success message' do
        session.must_have_success :list_created
      end

      it 'has the correct title' do
        title = selector('.todo-list h2').must_have_one
        title.must_be_heading 2, @name
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'create multiple lists' do
      before do
        @storage.create_todo_list 'Bucket'
        @storage.create_todo_list 'Groceries'
        post Route.create_todo_list, list_name: 'Homework'
        must_redirect_to :lists
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'does have a success message' do
        session.must_have_success :list_created
      end

      describe with_id 'the list' do
        before do
          lists = selector('.todo-list').must_have 3
          @list = lists[2]
        end

        it 'is an incomplete list' do
          @list.must_be_class 'incomplete'
        end

        it 'has a link to the correct view page' do
          link = selector('a', @list).must_have_one
          link.must_be_link Route.view_list(3)
        end

        it 'has the correct title' do
          title = selector('h2', @list).must_have_one
          title.must_be_heading 2, 'Homework'
        end

        it 'has the correct counts' do
          counts = selector('p', @list).must_have_one
          counts.must_be_p '0 / 0'
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'create multiple lists with some incomplete' do
      before do
        @storage.create_todo_list 'Bucket'
        @storage.create_todo_list 'Groceries'
        @storage.create_todo_item 2, 'Apples'
        @storage.mark_all_complete 2
        post Route.create_todo_list, list_name: 'Homework'
        must_redirect_to :lists
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'does have a success message' do
        session.must_have_success :list_created
      end

      describe with_id 'the list' do
        before do
          lists = selector('.todo-list').must_have 3
          @list = lists[1]
        end

        it 'is an incomplete list' do
          @list.must_be_class 'incomplete'
        end

        it 'has a link to the correct view page' do
          link = selector('a', @list).must_have_one
          link.must_be_link Route.view_list(3)
        end

        it 'has the correct title' do
          title = selector('h2', @list).must_have_one
          title.must_be_heading 2, 'Homework'
        end

        it 'has the correct counts' do
          counts = selector('p', @list).must_have_one
          counts.must_be_p '0 / 0'
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'create list with empty name' do
      before do
        post Route.create_todo_list, list_name: ''
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
        input.must_be_input value: '', placeholder: @message.ui(:list_name)
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'create list with overly long name' do
      before do
        @name = 'a' * 101
        post Route.create_todo_list, list_name: @name
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
        input.must_be_input value: @name, placeholder: @message.ui(:list_name)
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'create list with duplicate name' do
      before do
        @name = 'XyzzyX'
        @storage.create_todo_list @name
        post Route.create_todo_list, list_name: @name
      end

      it 'shows the correct page' do
        must_load :new_list
      end

      it 'has an error message' do
        session.must_have_error :list_name_unique
      end

      it 'does not have a success message' do
        session.wont_have_success
      end

      it 'has an input box for the list name' do
        input = selector('input[name="list_name"][type="text"]').must_have_one
        input.must_be_input value: @name, placeholder: @message.ui(:list_name)
      end
    end
  end
end
