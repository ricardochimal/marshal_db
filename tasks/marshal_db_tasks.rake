namespace :db do
	desc "Dump schema and data to db/schema.rb and db/data.yml"
	task(:dump => [ "db:schema:dump", "db:data:dump" ])

	desc "Load schema and data from db/schema.rb and db/data.yml"
	task(:load => [ "db:schema:load", "db:data:load" ])

	namespace :data do
		def db_dump_directory
			"#{RAILS_ROOT}/db/marshal_db"
		end

		desc "Dump contents of database to db/marshal_db"
		task(:dump => :environment) do
			MarshalDb.dump(db_dump_directory)
		end

		desc "Load contents of db/marshal_db into database"
		task(:load => :environment) do
			MarshalDb.load(db_dump_directory)
		end
	end
end
