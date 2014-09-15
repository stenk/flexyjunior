class CustomTableError < StandardError
end

class CustomTable
  @database ||= DB

  class <<self
    attr_accessor :database

    def all_names
      tables = @database.tables
      tables.select! { |t| t.to_s.start_with?('_') }
      tables.map! { |t| t.to_s[1..-1].to_sym }
    end
  end

  attr_accessor :name
  attr_reader :row_errors

  def initialize(name)
    validate_name(name)
    @name = name.to_sym
    @dbname = "_#{name}".to_sym
    @database = self.class.database

    @row_errors = nil
    @dataset = nil
  end

  def exists?
    self.class.all_names.include?(@name)
  end

  def schema
    schema = {}
    indexes = self.index_fields
    sequel_schema = @database.schema(@dbname)

    sequel_schema.each do |field|
      field_name, field_opts = field
      schema[field_name] = {
        name: field_name,
        type: field_opts[:db_type],
        primary_key: field_opts[:primary_key],
        null: field_opts[:allow_null],
        default: field_opts[:default],
        index: indexes.include?(field_name)
      }
    end

    schema
  end

  def index_fields
    fields = []
    index_list = @database["PRAGMA index_list(#{@dbname})"]
    index_list.each do |index|
      index_name = index[:name]
      index_info = @database["PRAGMA index_info(#{index_name})"].all
      fields << index_info[0][:name].to_sym
    end
    fields
  end

  def user_schema
    schema = self.schema
    schema.delete(:id)
    schema
  end

  def create(schema)
    @database.create_table @dbname do
      primary_key :id
      schema.each do |field_name, field_opts|
        type = field_opts[:type] || field_opts['type']
        column field_name, type, field_opts
      end
    end
  end

  def delete
    @database.drop_table(@dbname)
  end

  def rows(opts = {})
    rows = dataset
    rows = rows.limit(opts[:limit]) if opts[:limit]
    rows = rows.offset(opts[:offset]) if opts[:offset]
    rows.all
  end

  def rows_count
    dataset.count
  end

  def insert_row(row)
    validate_row(row)
    dataset.insert(row) unless row_errors
  end

  def update_row(id, data)
    data = data.dup
    data.delete(:id)
    data.delete('id')
    return if data.empty?

    validate_row(data)

    if @row_errors
      @row_errors.select! do |key, value|
        data.include?(key) || data.include?(key.to_s)
      end
      @row_errors = nil if @row_errors.empty?
    end

    dataset.where(id: id).update(data) unless @row_errors
  end

  def find_row(hash)
    dataset[hash]
  end

  def delete_row(id)
    dataset.where(id: id).delete
  end

  protected

  def dataset
    @dataset ||= @database[@dbname]
  end

  def validate_name(name)
    unless name.to_s =~ /\A[0-9A-Za-z_]+\z/
      raise CustomTableError.new("'#{name}' isn't a valid name for custom table")
    end
  end

  def validate_row(row)
    @row_errors = {}

    user_schema.each do |field_name, field_opts|
      value = row[field_name.to_sym] || row[field_name.to_s]
      type = field_opts[:type]
      null = field_opts[:null]
      default = field_opts[:default]

      if value.nil? && !null && !default
        @row_errors[field_name] = "can't be null"
      elsif type == 'integer'
        validate_integer(value, field_name, field_opts)
      elsif type.start_with?('double')
        validate_float(value, field_name, field_opts)
      elsif type == 'date'
        validate_date(value, field_name, field_opts)
      end
    end

    @row_errors = nil if @row_errors.empty?
  end

  def validate_integer(value, field_name, field_opts)
    if value && !value.is_a?(Integer) && value !~ /\A\d+\z/
      @row_errors[field_name] = "invalid value"
    end
  end

  def validate_float(value, field_name, field_opts)
    if value && !value.is_a?(Float) && value !~ /\A\d+\.?\d*\z/
      @row_errors[field_name] = "invalid value"
    end
  end

  def validate_date(value, field_name, field_opts)
    if value && !value.is_a?(Date) && value !~ /\d\d\d\d-\d\d-\d\d\z/
      @row_errors[field_name] = "invalid value"
    end
  end
end
