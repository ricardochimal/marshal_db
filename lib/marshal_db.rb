require 'rubygems'
require 'active_record'

module MarshalDb
	METADATA_FILE = 'metadata.dat'

	def self.dump(directory)
		process do
			MarshalDb::Dump.dump(directory)
		end
	end

	def self.load(directory)
		process do
			MarshalDb::Load.load(directory)
		end
	end

	def self.process
		old_logger = ActiveRecord::Base.logger
		yield if block_given?
		ActiveRecord::Base.logger = old_logger
	end
end


module MarshalDb::Dump
	class DirectoryError < RuntimeError ; end

	def self.dump(directory)
		directory_checks(directory)
		dump_metadata(directory)
		dump_data(directory)
	end

	def self.directory_checks(directory)
		if File.exists?(directory) and !File.directory?(directory)
			raise DirectoryError, "ERROR: #{directory} is not a directory!"
		end

		if !File.exists?(directory)
			FileUtils.mkdir(directory)
		end

		FileUtils.rm(Dir.glob("#{directory}/*"), :force => true)
	end

	def self.dump_data(directory)
		ActiveRecord::Base.connection.tables.each do |table|
			dump_table_data(directory, table)
		end
	end

	def self.dump_table_data(directory, table)
		page = 0
		each_table_page(table) do |records|
			File.open("#{directory}/#{table}.#{page}", 'w') { |f| f.write(Marshal.dump(records)) }
			page += 1
		end
	end

	def self.dump_metadata(directory)
		metadata = []
		ActiveRecord::Base.connection.tables.each do |table|
			metadata << table_metadata(table)
		end
		metadata

		File.open("#{directory}/#{MarshalDb::METADATA_FILE}", 'w') { |f| f.write(Marshal.dump(metadata)) }
	end

	def self.table_metadata(table)
		metadata = {
			'table' => table,
			'columns' => table_column_names(table),
		}
	end

	def self.each_table_page(table, records_per_page=50000)
		id = table_column_names(table).first
		pages = table_pages(table, records_per_page) - 1

		(0..pages).to_a.each do |page|
			sql_limit = "LIMIT #{records_per_page} OFFSET #{records_per_page*page}"
			records = ActiveRecord::Base.connection.select_all("SELECT * FROM #{table} ORDER BY #{id} #{sql_limit}")
			yield records
		end
	end

	def self.table_pages(table, records_per_page)
		total_count = table_record_count(table)
		pages = (total_count.to_f / records_per_page).ceil
		pages
	end

	def self.table_record_count(table)
		ActiveRecord::Base.connection.select_one("SELECT COUNT(*) FROM #{table}").values.first.to_i
	end

	def self.table_column_names(table)
		ActiveRecord::Base.connection.columns(table).map { |c| c.name }
	end
end


module MarshalDb::Load
	def self.load(directory)
		metadata(directory).each do |m|
			truncate_table(m['table'])
			load_table_data(directory, m['table'], m['columns'])
		end
	end

	def self.load_table_data(directory, table, columns)
		data_files = table_data_files(directory, table)
		data_files.each do |data_file|
			records = Marshal.load(File.open("#{directory}/#{data_file}", 'r').read)
			load_records(table, columns, records)
		end
		reset_pk_sequence!(table)
	end

	def self.metadata(directory)
		Marshal.load(File.open("#{directory}/#{MarshalDb::METADATA_FILE}", 'r').read)
	end

	def self.table_data_files(directory, table)
		files = Dir.glob("#{directory}/#{table}.*")
		files.map! { |file| File.basename(file) }
		files.reject! { |file| file == MarshalDb::METADATA_FILE }
		files
	end

	def self.truncate_table(table)
		begin
			ActiveRecord::Base.connection.execute("TRUNCATE #{table}")
		rescue Exception
			ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
		end
	end

	def self.load_records(table, columns, records)
		records.each do |record|
			data = columns.map { |c| ActiveRecord::Base.connection.quote(record[c]) }
			ActiveRecord::Base.connection.execute("INSERT INTO #{table} (#{columns.join(',')}) VALUES (#{data.join(',')})")
		end
	end

	def self.reset_pk_sequence!(table)
		if ActiveRecord::Base.connection.respond_to?(:reset_pk_sequence!)
			ActiveRecord::Base.connection.reset_pk_sequence!(table)
		end
	end
end
