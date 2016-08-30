#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for DatabasePersistence class.

require_relative 'test_helpers'

#------------------------------------------------------------------------------

describe File.basename(__FILE__).to_s do
  include TestHelpers

  eval TestHelpers.setup_code # rubocop:disable Eval

  #----------------------------------------------------------------------------

  describe with_id 'initialization and finish' do
    it 'opens and closes database connection' do
      code = proc do
        storage = DatabasePersistence.new
        storage.finish
      end

      code.must_be_silent
    end
  end

  #----------------------------------------------------------------------------

  describe with_id 'database tests' do
    before do
      @storage = DatabasePersistence.new
    end

    after do
      @storage.finish
    end

    #--------------------------------------------------------------------------

    describe with_id 'create_todo_list' do
      it 'is silent' do
        assert_silent do
          @storage.create_todo_list 'Groceries'
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'create_todo_item' do
      before do
        @storage.create_todo_list 'Groceries'
        @storage.create_todo_list 'Homework'

        list1 = @storage.find_todo_list 1
        list2 = @storage.find_todo_list 2

        @storage.create_todo_item list1[:id], 'Fruit'

        @storage.create_todo_item list2[:id], 'Math'
        @storage.create_todo_item list2[:id], 'Physics'
        @storage.create_todo_item list2[:id], 'English'

        @list1 = @storage.find_todo_list 1
        @list2 = @storage.find_todo_list 2
        @todos1 = @storage.find_todo_items 1
        @todos2 = @storage.find_todo_items 2
      end

      it 'puts a todo on the list' do
        @todos1.size.must_equal 1
        @todos1.first.must_equal id:        1,
                                 list_id:   @list1[:id],
                                 name:      'Fruit',
                                 completed: false
      end

      it 'puts multiple todos on a list' do
        @todos2.size.must_equal 3
        @todos2[0].must_equal id:        4,
                              list_id:   @list2[:id],
                              name:      'English',
                              completed: false
        @todos2[1].must_equal id:        2,
                              list_id:   @list2[:id],
                              name:      'Math',
                              completed: false
        @todos2[2].must_equal id:        3,
                              list_id:   @list2[:id],
                              name:      'Physics',
                              completed: false
      end

      it 'cannot create a todo for a non-existent list' do
        @storage.create_todo_item(5, 'Xyz').must_be_nil
        @storage.error_message.must_match 'PG::ForeignKeyViolation'
        @storage.error_message.must_match 'insert or update on table "todos"'
        @storage.error_message.must_match 'Key (list_id)=(5) is not present'
      end

      it 'cannot take a null name' do
        @storage.create_todo_item(4, nil).must_be_nil
        @storage.error_message.must_match 'null value in column "name"'
        @storage.error_message.must_match 'PG::NotNullViolation'
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'size' do
      it 'returns 0 if no lists' do
        @storage.size.must_equal 0
      end

      describe with_id '... with non-empty list' do
        before do
          @storage.create_todo_list 'Groceries'
          @storage.create_todo_list 'Homework'
          @storage.create_todo_list 'Packing'

          list1 = @storage.find_todo_list 1
          list2 = @storage.find_todo_list 2

          @storage.create_todo_item list1[:id], 'Fruit'

          @storage.create_todo_item list2[:id], 'Math'
          @storage.create_todo_item list2[:id], 'Physics'
          @storage.create_todo_item list2[:id], 'English'
        end

        it 'counts todo lists' do
          @storage.size.must_equal 3
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'find_todo_list' do
      it 'does not find anything on an empty list' do
        @storage.find_todo_list(1).must_be_nil
        @storage.error_message.must_equal @message.error(:no_todos_list)
      end

      describe with_id '... with non-empty list' do
        before do
          @storage.create_todo_list 'Groceries'
          @storage.create_todo_list 'Homework'
          @storage.create_todo_list 'Packing'

          list1 = @storage.find_todo_list 1
          list2 = @storage.find_todo_list 2

          @storage.create_todo_item list1[:id], 'Fruit'

          @storage.create_todo_item list2[:id], 'Math'
          @storage.create_todo_item list2[:id], 'Physics'
          @storage.create_todo_item list2[:id], 'English'
        end

        it 'finds list id 1' do
          list1 = @storage.find_todo_list 1
          list1[:name].must_equal 'Groceries'
        end

        it 'finds list id 2' do
          list2 = @storage.find_todo_list 2
          list2[:name].must_equal 'Homework'
        end

        it 'finds list id 3' do
          list3 = @storage.find_todo_list 3
          list3[:name].must_equal 'Packing'
        end

        it 'does not find list id 4' do
          list4 = @storage.find_todo_list 4
          list4.must_be_nil
          @storage.error_message.must_equal @message.error(:no_todos_list)
        end

        it 'constructs a proper list for return' do
          todos2 = @storage.find_todo_items 2
          todos2.size.must_equal 3
          todos2[0].must_equal id:        4,
                               list_id:   2,
                               name:      'English',
                               completed: false
          todos2[1].must_equal id:        2,
                               list_id:   2,
                               name:      'Math',
                               completed: false
          todos2[2].must_equal id:        3,
                               list_id:   2,
                               name:      'Physics',
                               completed: false
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'find_todo_items' do
      it 'does not find anything on an empty list' do
        @storage.find_todo_items(1).must_be_empty
      end

      describe with_id '... with non-empty list' do
        before do
          @storage.create_todo_list 'Groceries'
          @storage.create_todo_list 'Homework'
          @storage.create_todo_list 'Packing'

          list1 = @storage.find_todo_list 1
          list2 = @storage.find_todo_list 2

          @storage.create_todo_item list1[:id], 'Fruit'

          @storage.create_todo_item list2[:id], 'Math'
          @storage.create_todo_item list2[:id], 'Physics'
          @storage.create_todo_item list2[:id], 'English'
        end

        it 'finds todos for list id 1' do
          todos1 = @storage.find_todo_items 1
          todos1.size.must_equal 1
          todos1[0].must_equal id:        1,
                               list_id:   1,
                               completed: false,
                               name:      'Fruit'
        end

        it 'finds todos for list id 2' do
          todos2 = @storage.find_todo_items 2
          todos2.size.must_equal 3
          todos2[0].must_equal id:        4,
                               list_id:   2,
                               name:      'English',
                               completed: false
          todos2[1].must_equal id:        2,
                               list_id:   2,
                               name:      'Math',
                               completed: false
          todos2[2].must_equal id:        3,
                               list_id:   2,
                               name:      'Physics',
                               completed: false
        end

        it 'finds todos for list id 3' do
          todos3 = @storage.find_todo_items 3
          todos3.must_be_empty
        end

        it 'does not find todos for list id 4' do
          todos4 = @storage.find_todo_items 4
          todos4.must_be_empty
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'all_lists' do
      it 'does not find anything on an empty list' do
        @storage.all_lists.must_be_empty
      end

      describe with_id '... with non-empty list' do
        before do
          @storage.create_todo_list 'Groceries'
          @storage.create_todo_list 'Homework'
          @storage.create_todo_list 'Packing'

          list1 = @storage.find_todo_list 1
          list2 = @storage.find_todo_list 2

          @storage.create_todo_item list1[:id], 'Fruit'

          @storage.create_todo_item list2[:id], 'Math'
          @storage.create_todo_item list2[:id], 'Physics'
          @storage.create_todo_item list2[:id], 'English'
        end

        it 'returns all lists' do
          @storage.all_lists.must_equal [
            {
              id:                    1,
              name:                  'Groceries',
              todos_remaining_count: 1,
              todos_count:           1,
              completed:             false
            },
            {
              id:                    2,
              name:                  'Homework',
              todos_remaining_count: 3,
              todos_count:           3,
              completed:             false
            },
            {
              id:                    3,
              name:                  'Packing',
              todos_remaining_count: 0,
              todos_count:           0,
              completed:             false
            }
          ]
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'update_list_name' do
      it 'does not find anything on an empty list' do
        @storage.update_list_name(1, 'Abc').must_equal false
      end

      describe with_id '... with non-empty list' do
        before do
          @storage.create_todo_list 'Groceries'
          @storage.create_todo_list 'Homework'
          list1 = @storage.find_todo_list 1
          @storage.create_todo_item list1[:id], 'Fruit'
        end

        it 'changes name for list' do
          @storage.update_list_name(1, 'Abc').must_equal true

          list = @storage.find_todo_list(1)
          list.must_equal id:                    1,
                          name:                  'Abc',
                          todos_remaining_count: 1,
                          todos_count:           1,
                          completed:             false
        end

        it 'cannot rename list to an existing name' do
          @storage.update_list_name(2, 'Groceries').must_be_nil
          @storage.error_message.must_equal @message.error(:list_name_unique)
        end

        it 'cannot rename list to null' do
          @storage.update_list_name(2, nil).must_be_nil
          @storage.error_message.must_match 'null value in column "name"'
          @storage.error_message.must_match 'PG::NotNullViolation'
        end

        it 'cannot rename non-existing list' do
          @storage.update_list_name(3, 'xyz').must_equal false
          @storage.error_message.must_equal @message.error(:no_todos_list)
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'mark_todo' do
      it 'does not find anything on an empty list' do
        @storage.mark_todo(1, 1, true).must_equal false
      end

      describe with_id '... with non-empty list' do
        before do
          @storage.create_todo_list 'Groceries'
          @storage.create_todo_list 'Homework'
          @storage.create_todo_list 'Packing'

          list1 = @storage.find_todo_list 1
          list2 = @storage.find_todo_list 2

          @storage.create_todo_item list1[:id], 'Fruit'

          @storage.create_todo_item list2[:id], 'Math'
          @storage.create_todo_item list2[:id], 'Physics'
          @storage.create_todo_item list2[:id], 'English'
        end

        it 'changes status for math' do
          @storage.mark_todo(2, 2, true).must_equal true
          todos = @storage.find_todo_items 2
          todos[0][:completed].must_equal false
          todos[1][:completed].must_equal false
          todos[2][:completed].must_equal true
        end

        it 'changes status for physics' do
          @storage.mark_todo(2, 3, true).must_equal true
          todos = @storage.find_todo_items 2
          todos[0][:completed].must_equal false
          todos[1][:completed].must_equal false
          todos[2][:completed].must_equal true
        end

        it 'does nothing if no such todo' do
          @storage.mark_todo(2, 5, true).must_equal false
          @storage.error_message.must_equal @message.error(:no_todo)
          todos = @storage.find_todo_items 2
          todos[0][:completed].must_equal false
          todos[1][:completed].must_equal false
          todos[2][:completed].must_equal false
        end

        it 'changes not toggles from true' do
          @storage.mark_todo(2, 3, true).must_equal true
          @storage.mark_todo(2, 3, true).must_equal true
          todos = @storage.find_todo_items 2
          todos[0][:completed].must_equal false
          todos[1][:completed].must_equal false
          todos[2][:completed].must_equal true
        end

        it 'changes not toggles from false' do
          @storage.mark_todo(2, 3, false).must_equal true
          todos = @storage.find_todo_items 2
          todos[0][:completed].must_equal false
          todos[1][:completed].must_equal false
          todos[2][:completed].must_equal false
        end

        it 'reverses changes' do
          @storage.mark_todo(2, 3, true).must_equal true
          @storage.mark_todo(2, 3, false).must_equal true
          todos = @storage.find_todo_items 2
          todos[0][:completed].must_equal false
          todos[1][:completed].must_equal false
          todos[2][:completed].must_equal false
        end

        it 'cannot rename list to an existing name' do
          @storage.mark_todo(2, 3, nil).must_be_nil
          @storage.error_message.must_match 'null value in column "completed"'
          @storage.error_message.must_match 'PG::NotNullViolation'
        end

        it 'cannot rename list that does not exist' do
          @storage.mark_todo(4, 3, nil).must_equal false
          @storage.error_message.must_equal @message.error(:no_todos_list)
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'mark_all_complete' do
      it 'returns false if no lists' do
        @storage.mark_all_complete(1).must_equal false
      end

      describe with_id '... with non-empty list' do
        before do
          @storage.create_todo_list 'Groceries'
          @storage.create_todo_list 'Homework'
          @storage.create_todo_list 'Packing'

          list1 = @storage.find_todo_list 1
          list2 = @storage.find_todo_list 2

          @storage.create_todo_item list1[:id], 'Fruit'

          @storage.create_todo_item list2[:id], 'Math'
          @storage.create_todo_item list2[:id], 'Physics'
          @storage.create_todo_item list2[:id], 'English'
        end

        it 'marks all groceries as complete' do
          @storage.mark_all_complete(1).must_equal true
          todos = @storage.find_todo_items 1
          todos[0][:completed].must_equal true
        end

        it 'marks all homework as complete' do
          @storage.mark_all_complete(2).must_equal true
          todos = @storage.find_todo_items 2
          todos[0][:completed].must_equal true
          todos[1][:completed].must_equal true
          todos[2][:completed].must_equal true
        end

        it 'returns false on empty todo list' do
          @storage.mark_all_complete(3).must_equal false
          @storage.error_message.must_be_nil
        end

        it 'returns false if no such list' do
          @storage.mark_all_complete(4).must_equal false
          @storage.error_message.must_equal @message.error(:no_todos_list)
        end

        it 'does not toggle' do
          @storage.mark_all_complete(2).must_equal true
          @storage.mark_all_complete(2).must_equal true
          todos = @storage.find_todo_items 2
          todos[0][:completed].must_equal true
          todos[1][:completed].must_equal true
          todos[2][:completed].must_equal true
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'delete_todo_item' do
      it 'returns false if no lists' do
        @storage.delete_todo_item(1, 1).must_equal false
      end

      describe with_id '... with non-empty list' do
        before do
          @storage.create_todo_list 'Groceries'
          @storage.create_todo_list 'Homework'
          @storage.create_todo_list 'Packing'

          list1 = @storage.find_todo_list 1
          list2 = @storage.find_todo_list 2

          @storage.create_todo_item list1[:id], 'Fruit'

          @storage.create_todo_item list2[:id], 'Math'
          @storage.create_todo_item list2[:id], 'Physics'
          @storage.create_todo_item list2[:id], 'English'
        end

        it 'returns false if no todos' do
          @storage.delete_todo_item(3, 1).must_equal false
          @storage.error_message.must_be_nil
        end

        it 'returns false if todo does not exist' do
          @storage.delete_todo_item(2, 1).must_equal false
          @storage.delete_todo_item(2, 5).must_equal false
          @storage.error_message.must_be_nil
        end

        it 'returns false with error if no todo list' do
          @storage.delete_todo_item(4, 1).must_equal false
          @storage.error_message.must_equal @message.error(:no_todos_list)
        end

        it 'deletes a single element at the beginning' do
          @storage.delete_todo_item(2, 2).must_equal true
          todos = @storage.find_todo_items 2
          todos.size.must_equal 2
          todos[0][:name].must_equal 'English'
          todos[1][:name].must_equal 'Physics'
        end

        it 'deletes a single element in the middle' do
          @storage.delete_todo_item(2, 3).must_equal true
          todos = @storage.find_todo_items 2
          todos.size.must_equal 2
          todos[0][:name].must_equal 'English'
          todos[1][:name].must_equal 'Math'
        end

        it 'deletes a single element at the end' do
          @storage.delete_todo_item(2, 4).must_equal true
          todos = @storage.find_todo_items 2
          todos.size.must_equal 2
          todos[0][:name].must_equal 'Math'
          todos[1][:name].must_equal 'Physics'
        end

        it 'deletes two elements' do
          @storage.delete_todo_item(2, 2).must_equal true
          @storage.delete_todo_item(2, 4).must_equal true
          todos = @storage.find_todo_items 2
          todos.size.must_equal 1
          todos[0][:name].must_equal 'Physics'
        end

        it 'deletes three elements' do
          @storage.delete_todo_item(2, 2).must_equal true
          @storage.delete_todo_item(2, 4).must_equal true
          @storage.delete_todo_item(2, 3).must_equal true
          todos = @storage.find_todo_items 2
          todos.size.must_equal 0
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'delete_todos_all' do
      it 'returns false if no lists' do
        @storage.delete_todos_all(1).must_equal false
      end

      describe with_id '... with non-empty list' do
        before do
          @storage.create_todo_list 'Groceries'
          @storage.create_todo_list 'Homework'
          @storage.create_todo_list 'Packing'

          list1 = @storage.find_todo_list 1
          list2 = @storage.find_todo_list 2

          @storage.create_todo_item list1[:id], 'Fruit'

          @storage.create_todo_item list2[:id], 'Math'
          @storage.create_todo_item list2[:id], 'Physics'
          @storage.create_todo_item list2[:id], 'English'
        end

        it 'deletes a one element todo list' do
          @storage.delete_todos_all(1).must_equal true
          @storage.find_todo_items(1).size.must_equal 0
          @storage.find_todo_items(2).size.must_equal 3
          @storage.find_todo_items(3).size.must_equal 0
        end

        it 'deletes a 3 element todo list' do
          @storage.delete_todos_all(2).must_equal true
          @storage.find_todo_items(1).size.must_equal 1
          @storage.find_todo_items(2).size.must_equal 0
          @storage.find_todo_items(3).size.must_equal 0
        end

        it 'deletes an empty todo list' do
          @storage.delete_todos_all(3).must_equal false
          @storage.error_message.must_be_nil

          @storage.find_todo_items(1).size.must_equal 1
          @storage.find_todo_items(2).size.must_equal 3
          @storage.find_todo_items(3).size.must_equal 0
        end

        it 'returns false if no such list' do
          @storage.delete_todos_all(4).must_equal false
          @storage.error_message.must_equal @message.error(:no_todos_list)

          @storage.find_todo_items(4).size.must_equal 0
        end
      end
    end

    #--------------------------------------------------------------------------

    describe with_id 'delete_todo_list' do
      it 'returns false if no lists' do
        @storage.delete_todo_list(1).must_equal false
      end

      describe with_id '... with non-empty list' do
        before do
          @storage.create_todo_list 'Groceries'
          @storage.create_todo_list 'Homework'
          @storage.create_todo_list 'Packing'

          list1 = @storage.find_todo_list 1
          list2 = @storage.find_todo_list 2
          @storage.create_todo_item list1[:id], 'Fruit'

          @storage.create_todo_item list2[:id], 'Math'
          @storage.create_todo_item list2[:id], 'Physics'
          @storage.create_todo_item list2[:id], 'English'
        end

        it 'deletes a one element list' do
          @storage.delete_todo_list(1).must_equal true
          @storage.find_todo_list(1).must_be_nil
          @storage.find_todo_items(1).size.must_equal 0
        end

        it 'deletes a 3 element list' do
          @storage.delete_todo_list(2).must_equal true
          @storage.find_todo_list(2).must_be_nil
          @storage.find_todo_items(2).size.must_equal 0
        end

        it 'deletes an empty list' do
          @storage.delete_todo_list(3).must_equal true
          @storage.find_todo_list(3).must_be_nil
          @storage.find_todo_items(3).size.must_equal 0
        end

        it 'returns false if no such list' do
          @storage.delete_todo_list(4).must_equal false
          @storage.error_message.must_equal @message.error(:no_todos_list)
          @storage.find_todo_list(4).must_be_nil
          @storage.find_todo_items(4).size.must_equal 0
        end
      end
    end
  end
end
