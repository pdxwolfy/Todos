# Copyright (c) 2016 Pete Hanson
# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.3.1'
gem 'erubis',          '~>2.7.0'
gem 'sinatra',         '~>1.4.7'
gem 'sinatra-contrib', '~>1.4.7'
gem 'pg',              '~>0.18.4'

group :development, :test do
  gem 'awesome_print',    '~>1.7.0'
  gem 'pry',              '~>0.10.4'
  gem 'pry-power_assert', '~>0.0.2'
end

group :development do
  gem 'thin', '~>1.7.0'
end

group :production do
  gem 'puma'
end

group :test do
  gem 'minitest',           '~>5.9.0'
  gem 'minitest-reporters', '~>1.1.10'
  gem 'nokogiri',           '~>1.6.8'
  gem 'rack',               '~>1.6.4'
  gem 'simplecov',          '~>0.12.0', require: false
end
