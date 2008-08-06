namespace :db do
	desc "Dump schema and data to db/schema.rb and db/marshal_db.zip"
	task(:dump => [ "db:schema:dump", "db:marshal:dump" ])

	desc "Load schema and data from db/schema.rb and db/marshal_db.zip"
	task(:load => [ "db:schema:load", "db:marshal:load" ])

	namespace :marshal do
		def db_dump_directory
			"#{RAILS_ROOT}/db/marshal_db"
		end

		desc "Dump contents of database to db/marshal_db.zip"
		task(:dump => :environment) do
			MarshalDb.dump(db_dump_directory)
		end

		desc "Load contents of db/marshal_db.zip into database"
		task(:load => :environment) do
			MarshalDb.load(db_dump_directory)
		end
	end
end
