require 'sinatra'
require_relative 'bootstrap'

helpers do
  def set_table_variables
    @table = CustomTable.new(params[:table_name])

    unless @table.exists?
      message = "Table '#{@table.name}' doesn't exist"
      halt 404, json(error: message)
    end

    if params[:row_id]
      query = {id: params[:row_id]}
      unless @row = @table.find_row(query)
        message = "Row doesn't exist"
        halt 404, json(error: message)
      end
    end

    if params[:json]
      json = JSON.load(params[:json])
      if json.is_a?(Hash)
        json.each do |key, value|
          params[key] = value
        end
      end
    end
  end

  def json(data = {})
    JSON.dump(data)
  end
end

get '/api/tables' do
  json tables: CustomTable.all_names
end

post '/api/tables' do
  table_data = JSON.load(params[:json])['table']
  table = CustomTable.new(table_data['name'])

  if table.exists?
    json error: "Table '#{table.name}' already exists"
  else
    table.create(table_data['fields'])
    json
  end
end

get '/api/tables/:table_name/spec' do
  set_table_variables
  json table: {name: @table.name, schema: @table.schema.values}
end

get '/api/tables/:table_name' do
  set_table_variables
  json rows: @table.rows(params)
end

delete '/api/tables/:table_name' do
  set_table_variables
  @table.delete
  json
end

post '/api/tables/:table_name' do
  set_table_variables

  row_id = @table.insert_row(params[:row])
  if @table.row_errors
    json errors: @table.row_errors
  else
    json row: @table.find_row(id: row_id)
  end
end

get '/api/tables/:table_name/:row_id' do
  set_table_variables
  json row: @row
end

patch '/api/tables/:table_name/:row_id' do
  set_table_variables
  @table.update_row(@row[:id], params[:row])
  if @table.row_errors
    json errors: @table.row_errors
  else
    json row: @table.find_row(id: @row[:id])
  end
end

delete '/api/tables/:table_name/:row_id' do
  set_table_variables
  @table.delete_row(@row[:id])
  json
end

get '/' do
  slim :index
end
