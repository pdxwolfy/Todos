#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for common page layout.

require_relative 'test_helpers'

#------------------------------------------------------------------------------

describe File.basename(__FILE__).to_s do
  include TestHelpers

  setup = File.read((Pathname(__FILE__) + '..' + 'test_setup.rb').to_s)
  eval setup # rubocop:disable Eval

  PAGES = {
    'lists'     => [:all_lists].freeze,
    'new_list'  => [:create_todo_list].freeze,
    'list'      => [:view_list, 1].freeze,
    'edit_list' => [:edit_todo_list, 1].freeze
  }.freeze

  describe with_id 'create database' do
    before do
      @storage = DatabasePersistence.new
      @storage.create_todo_list 'Groceries'
      @storage.create_todo_item 1, 'Apples'
    end

    after do
      @storage.finish
    end

    #--------------------------------------------------------------------------

    PAGES.each do |page, data|
      describe with_id page do
        before do
          method, arguments = *data
          @route = Route.public_send method, *arguments
          get @route
        end

        it 'shows the correct page' do
          must_load page
        end

        it 'uses en-US language' do
          selector('html[lang="en-US"]').must_have_one
        end

        it 'uses UTF-8 charset' do
          selector('meta[charset="UTF-8"]').must_have_one
        end

        it 'has proper page title' do
          title = selector('title').must_have_one
          title.must_be_title @message.ui(:app_title)
        end

        it 'has our app name' do
          heading = selector('h1').must_have_one
          heading.must_be_heading 1, @message.ui(:app_name)
        end

        it 'has a place for header links' do
          selector('div.actions').must_have_one
        end

        it 'does not have any flash messages' do
          selector('.flash').must_be_empty
        end

        it 'has a place for the main body' do
          selector('main').must_have_one
        end
      end
    end
  end
end
