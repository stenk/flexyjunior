require File.join(File.expand_path(File.dirname(__FILE__)), '../bootstrap')

DB.create_table :_people do
  primary_key :id
  String :name, null: false
  Float :salary
  Date :birthday, null: false
end

DB.create_table :_cars do
  primary_key :id
  String :model, null: false
  Integer :owner_id, index: true
  TrueClass :is_insured, null: false
end
