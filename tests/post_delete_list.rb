#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for 'post /lists/:list_id/destroy'.

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

    describe with_id 'delete todo list' do
      before do
        @name = 'Groceries'
        @storage.create_todo_list 'Keep This'
        @storage.create_todo_list @name
        @storage.create_todo_list 'Keep This Too'
        @storage.create_todo_item 2, 'Milk'
        @storage.create_todo_item 2, 'Eggs'
        post Route.delete_todo_list 2
        must_redirect_to :lists
      end

      it 'does not have an error message' do
        session.wont_have_error
      end

      it 'has a success message' do
        session.must_have_success :list_deleted
      end

      #------------------------------------------------------------------------

      describe with_id 'resulting list' do
        before do
          @lists = selector('.todo-list').must_have 2
        end

        it 'does not contain the deleted list' do
          heading = selector('h2', @lists).must_have 2
          heading[0].must_be_heading 2, 'Keep This'
          heading[1].must_be_heading 2, 'Keep This Too'
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'delete non-existent list' do
      before do
        post Route.delete_todo_list(1)
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
