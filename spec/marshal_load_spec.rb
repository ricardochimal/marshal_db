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

	it "should truncate the table" do
		ActiveRecord::Base.connection.stub!(:execute).with("TRUNCATE mytable").and_return(true)
		ActiveRecord::Base.connection.should_not_receive(:execute).with("DELETE FROM mytable")
		MarshalDb::Load.truncate_table('mytable')
	end

	it "should delete the table if truncate throws an exception" do
		ActiveRecord::Base.connection.should_receive(:execute).with("TRUNCATE mytable").and_raise()
		ActiveRecord::Base.connection.should_receive(:execute).with("DELETE FROM mytable").and_return(true)
		MarshalDb::Load.truncate_table('mytable')
	end

end