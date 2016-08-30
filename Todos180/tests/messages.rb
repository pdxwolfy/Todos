#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for Messages class.

require_relative 'test_helpers'

#------------------------------------------------------------------------------

describe File.basename(__FILE__).to_s do
  include TestHelpers

  eval TestHelpers.setup_code # rubocop:disable Eval

  #----------------------------------------------------------------------------

  describe with_id '@message object created' do
    before do
      @message = Messages.new
    end

    it 'returns the correct error message' do
      @message.error(:list_name_unique).must_equal 'List name must be unique.'
    end

    it 'returns a pre-formatted error message' do
      @message.error('Hello').must_equal 'Hello'
    end

    it 'returns the correct success message' do
      @message.success(:list_updated).must_equal 'The list has been updated.'
    end

    it 'returns the correct success message with substitution' do
      message = @message.success :todo_deleted, list_name: 'Groceries'
      message.must_equal 'The todo has been deleted from Groceries.'
    end

    it 'returns a pre-formatted success message' do
      @message.error("What's up doc?").must_equal "What's up doc?"
    end

    it 'returns the correct ui message' do
      @message.ui(:new_list).must_equal 'New List'
    end

    it 'returns the correct ui message with substitution' do
      @message.ui(:editing_list, name: 'Xyz').must_equal 'Editing Xyz'
    end

    it 'returns a pre-formatted ui message' do
      @message.error('Four score').must_equal 'Four score'
    end

    it 'does substitutions in preformatted messages' do
      message = "Hey %{name}! What's up, %{nickname}? You are %{age} years old."
      message = @message.ui message, name: 'Pete', age: 59, nickname: 'Wolfy'
      message.must_equal "Hey Pete! What's up, Wolfy? You are 59 years old."
    end
  end
end
