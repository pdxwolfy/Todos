#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for 'get /index'.

require_relative 'test_helpers'

#------------------------------------------------------------------------------

describe File.basename(__FILE__).to_s do
  include TestHelpers

  setup = File.read((Pathname(__FILE__) + '..' + 'test_setup.rb').to_s)
  eval setup # rubocop:disable Eval

  describe with_id 'redirects' do
    it "redirects to #{Route.all_lists}" do
      get Route.index
      must_redirect_to :lists
    end
  end
end
