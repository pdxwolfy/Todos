#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for 'get /lists'.

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

    describe with_id 'no lists' do
      before do
        get Route.all_lists
      end

      it 'has a create list button' do
        button = selector('.add').must_have_one
        button.must_be_link Route.create_todo_list, @message.ui(:new_list)
      end

      it 'has no lists' do
        selector('li.todo-list').must_be_empty
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'multiple lists' do
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
        @storage.mark_todo 5, 6, true

        @storage.create_todo_list 'Homework III'   # list_id == 6
        @storage.create_todo_item 6, 'Math'        # todo_id == 7
        @storage.create_todo_item 6, 'Ruby'        # todo_id == 8
        @storage.mark_todo 6, 7, true

        @storage.create_todo_list 'Homework IV'    # list_id == 7
        @storage.create_todo_item 7, 'Math'        # todo_id == 9
        @storage.create_todo_item 7, 'Ruby'        # todo_id == 10
        @storage.mark_all_complete 7

        get Route.all_lists
      end

      it 'has a create list button' do
        button = selector('.add').must_have_one
        button.must_be_link Route.create_todo_list, @message.ui(:new_list)
      end

      it 'has 7 lists' do
        selector('.todo-list').must_have 7
      end

      describe with_id 'the active lists' do
        before do
          @lists = selector('.todo-list')
        end

        it 'have 5 incomplete lists at start' do
          @lists[0].must_be_class 'incomplete'
          @lists[1].must_be_class 'incomplete'
          @lists[2].must_be_class 'incomplete'
          @lists[3].must_be_class 'incomplete'
          @lists[4].must_be_class 'incomplete'
        end

        it 'have 2 complete lists at end' do
          @lists[5].must_be_class 'complete'
          @lists[6].must_be_class 'complete'
        end

        it 'have link to the correct view pages' do
          links = selector('a', @lists).must_have 7
          links[0].must_be_link Route.view_list(1)
          links[1].must_be_link Route.view_list(2)
          links[2].must_be_link Route.view_list(4)
          links[3].must_be_link Route.view_list(5)
          links[4].must_be_link Route.view_list(6)
          # completed lists at bottom
          links[5].must_be_link Route.view_list(3)
          links[6].must_be_link Route.view_list(7)
        end

        it 'have a links to the correct view pages' do
          names = selector('h2', @lists).must_have 7
          names[0].must_be_heading 2, 'Bucket'
          names[1].must_be_heading 2, 'Groceries I'
          names[2].must_be_heading 2, 'Homework I'
          names[3].must_be_heading 2, 'Homework II'
          names[4].must_be_heading 2, 'Homework III'
          # completed lists at bottom
          names[5].must_be_heading 2, 'Groceries II'
          names[6].must_be_heading 2, 'Homework IV'
        end

        it 'have the correct counts' do
          counts = selector('p', @lists).must_have 7
          counts[0].must_be_p '0 / 0'
          counts[1].must_be_p '1 / 1'
          counts[2].must_be_p '2 / 2'
          counts[3].must_be_p '1 / 2'
          counts[4].must_be_p '1 / 2'
          counts[5].must_be_p '0 / 1'
          counts[6].must_be_p '0 / 2'
        end
      end
    end
  end
end
