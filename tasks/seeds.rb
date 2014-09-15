require File.join(File.expand_path(File.dirname(__FILE__)), '../bootstrap')

srand(0)

DB.transaction do
  people = DB[:_people]
  100.times do
    people.insert(
      name: Faker::Name.name,
      salary: rand(10) == 0 ? nil : 100 + rand(1000),
      birthday: Time.at(rand(10 ** 9)).to_date,
    )
  end

  cars = DB[:_cars]
  100.times do
    cars.insert(
      model: Faker::Name.name,
      owner_id: rand(10) == 0 ? nil : rand(100),
      is_insured: rand(2) == 0,
    )
  end
end
