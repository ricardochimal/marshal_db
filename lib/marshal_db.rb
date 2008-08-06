require 'rubygems'
require 'active_record'

module MarshalDb
	def self.dump(directory)
		disable_logger
		MarshalDb::Dump.dump(directory)
		reenable_logger
	end

	def self.load(directory)
	end

	def self.disable_logger
		@@old_logger = ActiveRecord::Base.logger
		ActiveRecord.Base.logger = nil
	end

	def self.reenable_logger
		ActiveRecord::Base.logger = @@old_logger
	end
end


module MarshalDb::Dump
	def self.dump(directory)
		directory_checks(directory)
		dump_metadata(directory)
		dump_data(directory)
	end

	def self.directory_checks(directory)
		if File.exists?(directory) and !File.directory?(directory)
			#$stderr.print "ERROR: #{directory} is not a directory!\n"
			raise "ERROR: #{directory} is not a directory!\n"
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

		File.open("#{directory}/metadata.dat", 'w') { |f| f.write(Marshal.dump(metadata)) }
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
	end

	def self.truncate_table(table)
		begin
			ActiveRecord::Base.connection.execute("TRUNCATE #{table}")
		rescue Exception
			ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
		end
	end
end
