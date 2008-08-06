require 'rubygems'
require 'active_record'

module MarshalDb
	def self.dump(directory)
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
	end

	def self.table_metadata(table)
		metadata = {
			'table' => table,
			'columns' => table_column_names(table),
		}
	end

	def self.each_table_page(table, records_per_page=1000)
		total_count = table_record_count(table)
		pages = (total_count.to_f / records_per_page).ceil - 1
		id = table_column_names(table).first

		(0..pages).to_a.each do |page|
			sql_limit = "LIMIT #{records_per_page} OFFSET #{records_per_page*page}"
			records = ActiveRecord::Base.connection.select_all("SELECT * FROM #{table} ORDER BY #{id} #{sql_limit}")
			yield records
		end
	end

	def self.table_record_count(table)
		ActiveRecord::Base.connection.select_one("SELECT COUNT(*) FROM #{table}").values.first.to_i
	end

	def self.table_column_names(table)
		ActiveRecord::Base.connection.columns(table).map { |c| c.name }
	end
end
