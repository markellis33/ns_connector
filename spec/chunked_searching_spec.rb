require 'spec_helper'

class MagicResource 
	extend NSConnector::ChunkedSearching
	def initialize upstream_store
	end
	def self.type_id
		'magic'
	end
end

describe NSConnector::ChunkedSearching do
	before :all do
		# Keep things exciting
		NSConnector::Config[:no_threads] = rand(15) + 1
	end

	def mock_chunked_search
		(0..5).each do |i|
			MagicResource.should_receive(:grab_chunk).
				with('filters', i).ordered.and_return([1,2,3])
		end

		MagicResource.should_receive(:grab_chunk).
			with('filters', 6).ordered.
			and_raise(NSConnector::Errors::EndChunking, double)
	end

	it 'grabs a single chunk' do
		NSConnector::Restlet.should_receive(:execute!).
			with({
				:action => 'search', 
				:type_id => 'magic',
				:data => {
					:filters => 'filters',
					:chunk => 42
				}
			}).and_return(['retval'])

		MagicResource.should_receive(:new).with('retval')
		expect(MagicResource.grab_chunk('filters', 42)).to be_a(Array)
	end

	it 'listens to the config' do
		MagicResource.should_receive(:threaded_search_by_chunks).
			with('filters').ordered.
			and_return(1)
		MagicResource.should_receive(:normal_search_by_chunks).
			with('filters').ordered.
			and_return(2)

		expect(MagicResource.search_by_chunks('filters')).to eql(1)
		NSConnector::Config[:use_threads] = false
		expect(MagicResource.search_by_chunks('filters')).to eql(2)
	end

	it 'does a normal search correctly' do
		mock_chunked_search

		ret = MagicResource.normal_search_by_chunks('filters')

		expect(ret).to be_a(Array)
		# 5 iterations returning 3 each
		expect(ret).to have(6 * 3).things
	end

	it 'does a threaded search correctly' do
		mock_chunked_search

		ret = MagicResource.threaded_search_by_chunks('filters')
		expect(ret).to be_a(Array)
		expect(ret).to have(6 * 3).things
	end

end
