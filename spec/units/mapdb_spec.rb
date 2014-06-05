require_relative '../../lib/meda/core/mapdb'

shared_examples_for "a mapdb tree" do
  describe '#put' do
    it 'puts a string into a key' do
      subject['foo'] = 'bar'
      expect(subject['foo']).to eq('bar')
    end

    it 'puts a hash value into a key' do
      h = {'walk' => 't', 'swim' => 't', 'fly' => 't'}
      subject['duck_capabilities'] = h
      expect(subject['duck_capabilities']).to eq(h)
    end
  end

  describe '#clear' do
    it 'clears all keys' do
      subject['foo'] = 'bar'
      subject.clear
      expect(subject['foo']).to be_nil
    end
  end
end

describe MapDB::Tree do
  after(:each) { subject.clear }

  describe 'memory db' do
    subject do
      db = MapDB::DB.new
      db.tree :memory_tree
    end

    it_behaves_like 'a mapdb tree'
  end

  describe 'disk db' do
    subject do
      f = Tempfile.new('testdb')
      db = MapDB::DB.new(f.path)
      db.tree :disk_tree
    end

    it_behaves_like 'a mapdb tree'
  end
end

