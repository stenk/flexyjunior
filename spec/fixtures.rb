module Fixtures
  def self.setup(db)
    create_tables(db)
    insert_rows(db)
  end

  def self.clean(db)
    db.tables.each do |table|
      db.drop_table(table)
    end
  end

  def self.create_tables(db)
    db.create_table :_people do
      primary_key :id
      String :name, null: false
      Float :salary
      Date :birthday, null: false
    end

    db.create_table :_cars do
      primary_key :id
      String :model, null: false
      Integer :owner_id, index: true
      Float :price
      TrueClass :is_insured, null: false
    end

    db.create_table :noncustom do
      primary_key :id
    end
  end

  def self.insert_rows(db)
    cars = DB[:_cars]
    cars.insert(model: 'BMW X3', owner_id: 1, is_insured: true)
    cars.insert(model: 'Ford Focus', owner_id: nil, is_insured: false)
    cars.insert(model: 'Volvo S80', owner_id: 2, is_insured: false)

    people = DB[:_people]
    people.insert(name: 'John', salary: 200, birthday: Date.today)
  end
end

