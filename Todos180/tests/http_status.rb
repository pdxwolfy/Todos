#!/usr/bin/env ruby
# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true
#
# Tests for HTTPStatus module

require_relative 'test_helpers'

#------------------------------------------------------------------------------

describe File.basename(__FILE__).to_s do
  include TestHelpers

  eval TestHelpers.setup_code # rubocop:disable Eval

  #----------------------------------------------------------------------------

  describe with_id 'the tests' do
    it 'has a valid NO_CONTENT status' do
      HTTPStatus::NO_CONTENT.must_equal 204
    end
  end
end
