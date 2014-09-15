describe "API methods" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def jsonify(data)
    JSON.load JSON.dump(data)
  end

  before(:each) { Fixtures.setup(app.settings.database) }
  after(:each) { Fixtures.clean(app.settings.database) }

  let(:json) { JSON.load(last_response.body) }
  let(:status) do
    json.include?('error') || json.include?('errors') ? 'error' : 'ok'
  end

  describe "GET /api/tables" do
    let(:tables) { json['tables'] }

    it "responds with a list of custom tables" do
      get '/api/tables'
      expect(tables).to include('cars', 'people')
    end

    it "doesn't show non-custom tables" do
      get '/api/tables'
      expect(tables).to_not include('noncustom')
    end
  end

  describe "POST /api/tables" do
    it "creates new custom table" do
      json = JSON.dump table: {
        name: 'houses',
        fields: {
          address: { type: 'varchar', null: false },
          flats_count: { type: 'integer' },
          built_at: { type: 'datetime' }
        }
      }
      url = '/api/tables'
      expect { post url, json: json }.to change { DB.tables.size }.by(1)
    end
  end

  describe "GET /api/tables/:table_name/spec" do
    it "responds with table schema" do
      expected_json = jsonify table: {
        name: 'cars',
        schema: CustomTable.new(:cars).schema.values
      }
      get '/api/tables/cars/spec'
      expect(json).to eq(expected_json)
    end

    it "responds with an error if table doesn't exist" do
      get '/api/tables/foobar/spec'
      expect(status).to eq('error')
    end
  end

  describe "GET /api/tables/:table_name" do
    it "responds with a full list of rows" do
      get '/api/tables/cars'
      expected_json = jsonify rows: DB[:_cars].all
      expect(json).to eq(expected_json)
    end

    it "uses limit and offset parameters if they are given" do
      get '/api/tables/cars?offset=1&limit=1'
      expected_json = jsonify rows: DB[:_cars].limit(1).offset(1).all
      expect(json).to eq(expected_json)
    end

    it "responds with an error if table doesn't exist" do
      get '/api/tables/foobar'
      expect(status).to eq('error')
    end
  end

  describe "DELETE /api/tables/:table_name" do
    it "deletes the table" do
      json = JSON.dump table: {name: 'foo', fields: []}
      post '/api/tables', json: json
      expect { delete '/api/tables/foo' }.to change { DB.tables.size }.by(-1)
    end
  end

  describe "POST /api/tables/:table_name" do
    let(:valid_row) { {model: 'Kia Cerato', owner_id: 1, is_insured: false} }
    let(:invalid_row) { {model: 'Kia Cerato', owner_id: 1} }

    it "inserts new row in the table if data is valid" do
      url = '/api/tables/cars'
      cars = DB[:_cars]
      expect { post url, row: valid_row }.to change { cars.count }.by 1
    end

    it "responds with new row if data is valid" do
      post '/api/tables/cars', row: valid_row
      expect(json).to include('row')
    end

    it "responds with error if data isn't valid" do
      post '/api/tables/cars', row: invalid_row
      expect(status).to eq('error')
    end
  end

  describe "GET /api/tables/:table_name/:row_id" do
    let(:row_data) { json }

    it "responds with row data" do
      expected_json = jsonify row: DB[:_cars][id: 1]
      get '/api/tables/cars/1'
      expect(json).to eq(expected_json)
    end

    it "responds with error if table isn't found" do
      get '/api/tables/foobar/1'
      expect(status).to eq('error')
    end

    it "responds with error if row isn't found" do
      get '/api/tables/cars/111'
      expect(status).to eq('error')
    end
  end

  describe "PATCH /api/tables/:table_name/:row_id" do
    let(:url) { '/api/tables/cars/1' }
    let(:valid_data) { {row: {is_insured: false}} }
    let(:dataset) { DB[:_cars] }

    it "updates a row if data is valid" do
      expect { patch url, valid_data }
        .to change { dataset[id: 1][:is_insured] }.from(true).to(false)
    end

    it "responds with new row if data is valid" do
      patch url, valid_data
      expect(json).to include('row')
    end

    it "doesn't allow to change primary key value" do
      data = {row: {id: 33}}
      expect { patch url, data }
        .not_to change { dataset[model: 'BMW X3'][:id] }.from(1)
    end

    it "responds with error if data isn't valid" do
      patch url, row: {model: nil}
      expect(status).to eq('error')
    end

    it "responds with error if table isn't found" do
      patch '/api/tables/foobar/1', {}
      expect(status).to eq('error')
    end

    it "responds with error if row isn't found" do
      patch '/api/tables/cars/123', valid_data
      expect(status).to eq('error')
    end
  end

  describe "DELETE /api/tables/:table_name/:row_id" do
    it "deletes the row" do
      url = '/api/tables/cars/1'
      dataset = DB[:_cars]
      expect { delete url }.to change { dataset.count }.by -1
    end

    it "responds with error if table isn't found" do
      delete '/api/tables/foobar/1'
      expect(status).to eq('error')
    end
  end
end
