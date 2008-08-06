require File.dirname(__FILE__) + '/base'

describe MarshalDb::Dump do
	before do
		#File.stub!(:new).with('dump.yml', 'w').and_return(StringIO.new)

		ActiveRecord::Base = mock('ActiveRecord::Base', :null_object => true)
		ActiveRecord::Base.connection = mock('connection')
		ActiveRecord::Base.connection.stub!(:tables).and_return([ 'mytable' ])
		ActiveRecord::Base.connection.stub!(:columns).with('mytable').and_return([ mock('a',:name => 'a'), mock('b', :name => 'b') ])
		ActiveRecord::Base.connection.stub!(:select_one).and_return({"count"=>"2"})
		ActiveRecord::Base.connection.stub!(:select_all).and_return([ { 'a' => 1, 'b' => 2 }, { 'a' => 3, 'b' => 4 } ])
	end

	before(:each) do
		@io = StringIO.new
	end

	it "should return a list of column names" do
		MarshalDb::Dump.table_column_names('mytable').should == [ 'a', 'b' ]
	end

	it "should return the total number of records in a table" do
		MarshalDb::Dump.table_record_count('mytable').should == 2
	end

	it "should return the number of 'pages' in a table" do
		MarshalDb::Dump.stub!(:table_record_count).with('mytable').and_return(20)
		MarshalDb::Dump.table_pages('mytable', 7).should == 3
	end

	it "should return all records from the database and return them when there is only 1 page" do
		MarshalDb::Dump.each_table_page('mytable') do |records|
			records.should == [ { 'a' => 1, 'b' => 2 }, { 'a' => 3, 'b' => 4 } ]
		end
	end

	it "should paginate records from the database and return them" do
		ActiveRecord::Base.connection.stub!(:select_all).and_return([ { 'a' => 1, 'b' => 2 } ], [ { 'a' => 3, 'b' => 4 } ])

		records = [ ]
		MarshalDb::Dump.each_table_page('mytable', 1) do |page|
			page.size.should == 1
			records.concat(page)
		end

		records.should == [ { 'a' => 1, 'b' => 2 }, { 'a' => 3, 'b' => 4 } ]
	end

	it "should return the table's metadata" do
		MarshalDb::Dump.table_metadata('mytable').should == { 'table' => 'mytable', 'columns' => ['a', 'b'] }
	end

	it "should dump an array of all table's metadata to a file" do
		File.stub!(:open).with('test/metadata.dat', 'w').and_yield(@io)
		MarshalDb::Dump.dump_metadata('test')
		@io.rewind
		@io.read.should == Marshal.dump([ { 'table' => 'mytable', 'columns' => ['a', 'b'] } ])
	end

	it "should write out a table's data to a file" do
		File.stub!(:open).with('test/mytable.0', 'w').and_yield(@io)
		MarshalDb::Dump.stub!(:each_table_page).with('mytable').and_yield([ { 'a' => 1, 'b' => 2 }, { 'a' => 3, 'b' => 4 } ])
		MarshalDb::Dump.dump_table_data('test', 'mytable')
		@io.rewind
		@io.read.should == Marshal.dump([ { 'a' => 1, 'b' => 2 }, { 'a' => 3, 'b' => 4 } ])
	end

	it "should dump all table data" do
		MarshalDb::Dump.should_receive(:dump_table_data).with('test', 'mytable')
		MarshalDb::Dump.dump_data('test')
	end

	it "should call dump_metadata and dump_data" do
		MarshalDb::Dump.should_receive(:dump_metadata).with('test')
		MarshalDb::Dump.should_receive(:dump_data).with('test')
		MarshalDb::Dump.dump('test')
	end
end
