#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for todo Helpers.

require_relative 'test_helpers'

#------------------------------------------------------------------------------

describe File.basename(__FILE__).to_s do
  include TestHelpers
  include Helpers

  eval TestHelpers.setup_code # rubocop:disable Eval

  #----------------------------------------------------------------------------

  describe with_id 'app_name' do
    it 'returns our application name' do
      app_name.must_equal 'Todo Tracker'
    end
  end

  #----------------------------------------------------------------------------

  describe with_id 'app_title' do
    it 'returns our application title' do
      app_title.must_equal 'Todo Tracker'
    end
  end

  #----------------------------------------------------------------------------

  describe with_id 'stuff that accesses database' do
    before do
      @storage = DatabasePersistence.new
    end

    after do
      @storage.finish
    end

    #--------------------------------------------------------------------------

    describe with_id 'todo_list' do
      before do
        @storage.create_todo_list 'Dummy'
        @storage.create_todo_list 'Fruits'
        @storage.create_todo_item 2, 'Apples'
        @storage.create_todo_item 2, 'Bananas'
        @storage.create_todo_item 2, 'Cherries'
      end

      it 'returns nil if no list' do
        list = todo_list 3
        list.must_be_nil
      end

      it 'returns an empty list if list has no todos' do
        list = todo_list 1
        list.must_equal id:                    1,
                        name:                  'Dummy',
                        completed:             false,
                        todos_remaining_count: 0,
                        todos_count:           0
      end

      it 'returns a valid list if list has all incomplete todos' do
        list = todo_list 2
        list.must_equal id:                    2,
                        name:                  'Fruits',
                        completed:             false,
                        todos_remaining_count: 3,
                        todos_count:           3
      end

      it 'returns a valid list if list has all complete & incomplete todos' do
        @storage.mark_todo 2, 2, true
        list = todo_list 2
        list.must_equal id:                    2,
                        name:                  'Fruits',
                        completed:             false,
                        todos_remaining_count: 2,
                        todos_count:           3
      end

      it 'returns a valid list if list has all complete todos' do
        @storage.mark_all_complete 2
        list = todo_list 2
        list.must_equal id:                    2,
                        name:                  'Fruits',
                        completed:             true,
                        todos_remaining_count: 0,
                        todos_count:           3
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'get_lists' do
      it 'returns []] if no lists' do
        all_lists.must_equal []
      end

      describe with_id 'with data' do
        before do
          @storage.create_todo_list 'Dummy'
          @storage.create_todo_list 'Fruits'
          @storage.create_todo_item 2, 'Apples'
          @storage.create_todo_item 2, 'Bananas'
          @storage.create_todo_item 2, 'Cherries'
          @lists = all_lists
        end

        it 'returns 2 lists' do
          @lists.size.must_equal 2
        end

        it 'returns two correct todo lists' do
          @lists.must_equal [
            {
              id:                    1,
              name:                  'Dummy',
              completed:             false,
              todos_remaining_count: 0,
              todos_count:           0
            },
            {
              id:                    2,
              name:                  'Fruits',
              completed:             false,
              todos_remaining_count: 3,
              todos_count:           3
            }
          ]
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'todo_items' do
      before do
        @storage.create_todo_list 'Dummy'
      end

      it 'returns [] for an empty list' do
        todos = todo_items 1
        todos.must_equal []
      end

      it 'returns 1 for a single item list' do
        @storage.create_todo_item 1, 'Stuff'
        todos = todo_items 1
        todos[0].must_equal id: 1, list_id: 1, name: 'Stuff', completed: false
      end

      it 'returns 3 for a three item list' do
        @storage.create_todo_item 1, 'Stuff'
        @storage.create_todo_item 1, 'Xyz'
        @storage.create_todo_item 1, 'Abc'
        todos = todo_items 1
        todos[0].must_equal id: 3, list_id: 1, name: 'Abc', completed: false
        todos[1].must_equal id: 1, list_id: 1, name: 'Stuff', completed: false
        todos[2].must_equal id: 2, list_id: 1, name: 'Xyz', completed: false
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'todos_count' do
      before do
        @storage.create_todo_list 'Dummy'
      end

      it 'returns 0 for an empty list' do
        todos = @storage.find_todo_items 1
        todos_count(todos).must_equal 0
      end

      it 'returns 1 for a single item list' do
        @storage.create_todo_item 1, 'Stuff'
        todos = @storage.find_todo_items 1
        todos_count(todos).must_equal 1
      end

      it 'returns 3 for a three item list' do
        @storage.create_todo_item 1, 'Stuff'
        @storage.create_todo_item 1, 'Xyz'
        @storage.create_todo_item 1, 'Abc'
        todos = @storage.find_todo_items 1
        todos_count(todos).must_equal 3
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'todos_remaining_count' do
      before do
        @storage.create_todo_list 'Dummy'
      end

      it 'returns 0 for an empty list' do
        todos = @storage.find_todo_items 1
        todos_remaining_count(todos).must_equal 0
      end

      it 'returns 1 for a single item list with all items incomplete' do
        @storage.create_todo_item 1, 'Stuff'
        todos = @storage.find_todo_items 1
        todos_remaining_count(todos).must_equal 1
      end

      it 'returns 0 for a single item list with all items complete' do
        @storage.create_todo_item 1, 'Stuff'
        @storage.mark_todo 1, 1, true
        todos = @storage.find_todo_items 1
        todos_remaining_count(todos).must_equal 0
      end

      it 'returns 3 for a three item list with all items incomplete' do
        @storage.create_todo_item 1, 'Stuff'
        @storage.create_todo_item 1, 'Xyz'
        @storage.create_todo_item 1, 'Abc'
        todos = @storage.find_todo_items 1
        todos_remaining_count(todos).must_equal 3
      end

      it 'returns 2 for a three item list with one item complete' do
        @storage.create_todo_item 1, 'Stuff'
        @storage.create_todo_item 1, 'Xyz'
        @storage.create_todo_item 1, 'Abc'
        @storage.mark_todo 1, 2, true
        todos = @storage.find_todo_items 1
        todos_remaining_count(todos).must_equal 2
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'list_complete?' do
      before do
        @storage.create_todo_list 'Dummy'
      end

      it 'returns false for an empty list' do
        list = @storage.find_todo_list 1
        list_complete?(list).must_equal false
      end

      it 'returns false for a two item list with 1 item complete' do
        @storage.create_todo_item 1, 'Stuff'
        @storage.create_todo_item 1, 'Xyz'
        @storage.mark_todo 1, 1, true
        list = @storage.find_todo_list 1
        list_complete?(list).must_equal false
      end

      it 'returns true for a two item list with 2 item completes' do
        @storage.create_todo_item 1, 'Stuff'
        @storage.create_todo_item 1, 'Xyz'
        @storage.mark_todo 1, 1, true
        @storage.mark_todo 1, 2, true
        list = @storage.find_todo_list 1
        list_complete?(list).must_equal true
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'list_completion_class' do
      before do
        @storage.create_todo_list 'Dummy'
      end

      it 'returns incomplete for an empty list' do
        list = @storage.find_todo_list 1
        list_completion_class(list).must_equal 'incomplete'
      end

      it 'returns incomplete for a two item list with 1 item complete' do
        @storage.create_todo_item 1, 'Stuff'
        @storage.create_todo_item 1, 'Xyz'
        @storage.mark_todo 1, 1, true
        list = @storage.find_todo_list 1
        list_completion_class(list).must_equal 'incomplete'
      end

      it 'returns complete for a two item list with 2 item completes' do
        @storage.create_todo_item 1, 'Stuff'
        @storage.create_todo_item 1, 'Xyz'
        @storage.mark_todo 1, 1, true
        @storage.mark_todo 1, 2, true
        list = @storage.find_todo_list 1
        list_completion_class(list).must_equal 'complete'
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'todo_completion_class' do
      before do
        @storage.create_todo_list 'Dummy'
      end

      it 'returns complete for a complete todo' do
        @storage.create_todo_item 1, 'Stuff'
        @storage.create_todo_item 1, 'Xyz'
        @storage.mark_todo 1, 1, true
        todos = @storage.find_todo_items 1
        todo_completion_class(todos.last).must_equal 'complete'
      end

      it 'returns incomplete for an incomplete todo' do
        @storage.create_todo_item 1, 'Stuff'
        @storage.create_todo_item 1, 'Xyz'
        @storage.mark_todo 1, 1, true
        todos = @storage.find_todo_items 1
        todo_completion_class(todos.first).must_equal 'incomplete'
      end
    end
  end
end
