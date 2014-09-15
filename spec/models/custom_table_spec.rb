describe CustomTable do
  before(:each) { Fixtures.setup(DB) }
  after(:each) { Fixtures.clean(DB) }

  let(:cars) { CustomTable.new(:cars) }
  let(:people) { CustomTable.new(:people) }
  let(:pictures) { CustomTable.new(:pictures) }

  describe ".all_names" do
    it "returns a list of existing tables" do
      expect(CustomTable.all_names).to contain_exactly(:cars, :people)
    end
  end

  describe "#new" do
    it "creates an object" do
      expect { CustomTable.new(:foo) }.not_to raise_error
    end
  end

  describe "#exists?" do
    it "returns true if table exists" do
      expect(cars).to exist
    end

    it "returns false if table doesn't exist" do
      expect(pictures).not_to exist
    end
  end

  describe "#create" do
    let(:new_table) { CustomTable.new(:houses) }
    let(:schema) {{
      address: { type: 'varchar(255)', null: false },
      flats_count: { type: 'integer' },
      rent_price: { type: 'integer', null: false, index: true }
    }}

    it "creates a table" do
      new_table.create(schema)
      expect(new_table).to exist
    end

    it "adds all of specified fields to created table" do
      new_table.create(schema)
      expect(new_table.schema).to include(:address, :flats_count, :rent_price)
    end
  end

  describe "#index_fields" do
    it "returns a list of indexed fields" do
      expect(cars.index_fields).to contain_exactly(:owner_id)
    end
  end

  describe "#delete" do
    it "deletes table" do
      expect { cars.delete }.to change { DB.tables.size }.by(-1)
    end
  end

  describe "#rows" do
    it "returns table's rows" do
      expect(cars.rows).to eq(DB[:_cars].all)
    end

    it "supports offset parameter" do
      expect(cars.rows(offset: 1))
        .to eq(DB[:_cars].offset(1).all)
    end

    it "supports limit parameter" do
      expect(cars.rows(limit: 1))
        .to eq(DB[:_cars].limit(1).all)
    end
  end

  describe "#rows_count" do
    it "return rows count" do
      expect(cars.rows_count).to eq(DB[:_cars].count)
    end
  end

  describe "#insert_row" do
    let(:valid_row) {{ model: 'Opel Astra', is_insured: true }}
    let(:invalid_row) {{ model: 'Opel Astra' }}

    it "inserts a row if it's valid" do
      expect { cars.insert_row(valid_row) }
        .to change { cars.rows_count }.by(1)
    end

    it "doesn't insert new row if data isn't valid" do
      expect { cars.insert_row(invalid_row) }
        .not_to change { cars.rows_count }
    end

    it "gives an error list if data isn't valid" do
      cars.insert_row(invalid_row)
      expect(cars.row_errors).to include(:is_insured)
    end
  end

  describe "#update_row" do
    it "upates a row if data is valid" do
      cars.update_row(1, model: 'VAZ')
      expect(cars.find_row(id: 1)[:model]).to eq('VAZ')
    end
  end

  describe "#find_row" do
    it "returns a row" do
      expect(cars.find_row(id: 1)).to include(:id, :model, :is_insured)
    end

    it "returns nil if row isn't found" do
      expect(cars.find_row(id: 123)).to eq(nil)
    end
  end

  describe "#delete_row" do
    it "deletes a row" do
      expect { cars.delete_row(1) }.to change { cars.rows_count }.by(-1)
    end
  end

  describe "row validation" do
    let(:row) {{ model: 'Opel Astra', is_insured: true }}

    it "fails if null value is provided for non-nullable field" do
      row[:model] = nil
      cars.update_row(row[:id], row)
      expect(cars.row_errors).to include(:model)
    end

    it "fails if non-integer value is provided for integer field" do
      row[:owner_id] = 'abc'
      cars.update_row(row[:id], row)
      expect(cars.row_errors).to include(:owner_id)
    end

    it "fails if non-float value is provided for float field" do
      row[:price] = 'abc'
      cars.update_row(row[:id], row)
      expect(cars.row_errors).to include(:price)
    end

    it "fails if non-date value is provided for date field" do
      row = people.find_row(id: 1)
      people.update_row(row[:id], birthday: 'foo')
      expect(people.row_errors).to include(:birthday)
    end
  end
end
