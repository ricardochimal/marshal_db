namespace :db do
	namespace :marshal do
		def db_dump_directory
			"#{RAILS_ROOT}/db/marshal_db"
		end

		def db_dump_file
			"#{RAILS_ROOT}/db/marshal_db.zip"
		end

		desc "Dump contents of database to db/marshal_db.zip"
		task(:dump => :environment) do
			Rake::Task['db:schema:dump'].invoke
			MarshalDb.dump(db_dump_file, db_dump_directory)
		end

		desc "Load contents of db/marshal_db.zip into database"
		task(:load => :environment) do
			Rake::Task['db:schema:load'].invoke
			MarshalDb.load(db_dump_file, db_dump_directory)
		end
	end
end
