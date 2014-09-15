require 'sinatra'

ENV['RACK_ENV'] ||= 'development'
set :root, File.expand_path(File.dirname(__FILE__))
set :views, File.join(settings.root, 'views')

require 'rubygems'
require 'bundler/setup'
Bundler.require :default, ENV['RACK_ENV'].to_sym

configure :development do
  set :database, Sequel.connect('sqlite://development.db')
end

configure :test do
  set :database, Sequel.connect('sqlite::memory:')
end

DB = settings.database

require 'date'
require 'json'
require_relative 'models/custom_table'
