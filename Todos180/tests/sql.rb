#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for SQL class.

require_relative 'test_helpers'

#------------------------------------------------------------------------------

describe File.basename(__FILE__).to_s do
  include TestHelpers

  eval TestHelpers.setup_code # rubocop:disable Eval

  #----------------------------------------------------------------------------

  describe with_id 'initialization and finish' do
    it 'opens and closes database connection' do
      code = proc do
        sql = SQL.new DBNAME
        sql.finish
      end

      code.must_be_silent
    end
  end

  #----------------------------------------------------------------------------

  describe with_id 'database tests' do
    before do
      @sql = SQL.new DBNAME
    end

    after do
      @sql.finish
    end

    it 'opens correct database' do
      @sql.instance_variable_get(:@dbname).must_equal DBNAME
    end

    #--------------------------------------------------------------------------

    describe with_id 'SQL commands' do
      #------------------------------------------------------------------------

      describe with_id 'insert commands' do
        before do
          @pg_result = @sql.query 'INSERT INTO lists (name) VALUES ($1);',
                                  'Groceries'
        end

        it 'returns success' do
          @pg_result.cmd_tuples.must_equal 1
        end

        it 'does not produce an error message' do
          @sql.error_message.must_be_nil
        end

        it 'can retrieve an inserted record' do
          pg_result = @sql.query 'SELECT * FROM lists;'
          pg_result.must_be_instance_of PG::Result
          pg_result.ntuples.must_equal 1
          pg_result[0]['id'].must_equal '1'
          pg_result[0]['name'].must_equal 'Groceries'
        end
      end

      #------------------------------------------------------------------------

      describe with_id 'insert commands with uniqueness violation' do
        before do
          sql = 'INSERT INTO lists (name) VALUES ($1);'
          @sql.query sql, 'Groceries'
          @pg_result = @sql.query sql, 'Groceries'
        end

        it 'returns failure' do
          @pg_result.must_be_nil
        end

        it 'produces an error message' do
          @sql.error_message.must_equal @message.error(:list_name_unique)
        end
      end

      #------------------------------------------------------------------------

      describe with_id 'insert commands with not null violation' do
        before do
          @pg_result = @sql.query 'INSERT INTO lists (name) VALUES (null);'
        end

        it 'returns nil to show failure' do
          @pg_result.must_be_nil
        end

        it 'produces an error message' do
          @sql.error_message.must_match(/null value in column \"name\"/)
        end
      end

      #------------------------------------------------------------------------

      describe with_id 'delete commands' do
        before do
          @sql.query 'INSERT INTO lists (name) VALUES ($1);', 'Groceries'
          @sql.query 'INSERT INTO lists (name) VALUES ($1);', 'Homework'
        end

        #----------------------------------------------------------------------

        describe with_id 'delete all elements' do
          before do
            @pg_result = @sql.query 'DELETE FROM lists;'
          end

          it 'returns a PG::Result' do
            @pg_result.must_be_instance_of PG::Result
          end

          it 'returns 2 cmd tuples' do
            @pg_result.cmdtuples.must_equal 2
          end

          it 'does not produce an error message' do
            @sql.error_message.must_be_nil
          end
        end
      end

      #----------------------------------------------------------------------

      describe with_id 'delete no elements' do
        before do
          @pg_result = @sql.query 'DELETE FROM lists WHERE id = 5;'
        end

        it 'returns a PG::Result' do
          @pg_result.must_be_instance_of PG::Result
        end

        it 'returns 0 cmd tuples' do
          @pg_result.cmdtuples.must_equal 0
        end

        it 'does not produce an error message' do
          @sql.error_message.must_be_nil
        end
      end

      #------------------------------------------------------------------------

      describe with_id 'select commands' do
        before do
          @sql.query 'INSERT INTO lists (name) VALUES ($1);', 'Groceries'
          @sql.query 'INSERT INTO lists (name) VALUES ($1);', 'Homework'
        end

        #----------------------------------------------------------------------

        describe with_id 'select all elements' do
          before do
            @pg_result = @sql.query 'SELECT * FROM lists ORDER BY id;'
          end

          it 'returns a PG::Result' do
            @pg_result.must_be_instance_of PG::Result
          end

          it 'returns 2 tuples' do
            @pg_result.ntuples.must_equal 2
          end

          it 'returns the Groceries element first' do
            @pg_result[0]['id'].must_equal '1'
            @pg_result[0]['name'].must_equal 'Groceries'
          end

          it 'returns the Homework element last' do
            @pg_result[1]['id'].must_equal '2'
            @pg_result[1]['name'].must_equal 'Homework'
          end

          it 'does not produce an error message' do
            @sql.error_message.must_be_nil
          end
        end

        #----------------------------------------------------------------------

        describe with_id 'select just one element' do
          before do
            @pg_result = @sql.query 'SELECT * FROM lists WHERE id = 2;'
          end

          it 'returns a PG::Result' do
            @pg_result.must_be_instance_of PG::Result
          end

          it 'returns 1 tuples' do
            @pg_result.ntuples.must_equal 1
          end

          it 'returns the Homework element' do
            @pg_result[0]['id'].must_equal '2'
            @pg_result[0]['name'].must_equal 'Homework'
          end

          it 'does not produce an error message' do
            @sql.error_message.must_be_nil
          end
        end

        #----------------------------------------------------------------------

        describe with_id 'select no elements' do
          before do
            @pg_result = @sql.query 'SELECT * FROM lists WHERE id = 3;'
          end

          it 'returns a PG::Result' do
            @pg_result.must_be_instance_of PG::Result
          end

          it 'returns 0 tuples' do
            @pg_result.ntuples.must_equal 0
          end

          it 'does not produce an error message' do
            @sql.error_message.must_be_nil
          end
        end

        #----------------------------------------------------------------------

        describe with_id 'save_error' do
          it 'handles a nil message' do
            @sql.save_error(nil).must_be_nil
            @sql.error_message.must_be_nil
          end

          it 'handles a :symbolic message' do
            @sql.save_error(:no_todo).must_be_nil
            @sql.error_message.must_equal 'No such todo.'
          end

          it 'handles a non-symbolic message' do
            @sql.save_error('This is an error').must_be_nil
            @sql.error_message.must_equal 'This is an error'
          end

          it 'overrides a message' do
            @sql.save_error(:no_todo).must_be_nil
            @sql.save_error('what is up?').must_be_nil
            @sql.error_message.must_equal 'what is up?'
          end
        end

        #----------------------------------------------------------------------

        describe with_id 'update_error' do
          it 'handles a nil message' do
            @sql.update_error(nil).must_be_nil
            @sql.error_message.must_be_nil
          end

          it 'handles a :symbolic message' do
            @sql.update_error(:no_todo).must_be_nil
            @sql.error_message.must_equal 'No such todo.'
          end

          it 'handles a non-symbolic message' do
            @sql.update_error('This is an error').must_be_nil
            @sql.error_message.must_equal 'This is an error'
          end

          it 'does not override a message with nil' do
            @sql.update_error(:no_todo).must_be_nil
            @sql.update_error(nil).must_be_nil
            @sql.error_message.must_equal 'No such todo.'
          end

          it 'does not override a message with a non-nil' do
            @sql.update_error(:no_todo).must_be_nil
            @sql.update_error('Xyzzy').must_be_nil
            @sql.error_message.must_equal 'No such todo.'
          end
        end
      end
    end
  end
end
