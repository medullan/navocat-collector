require_relative '../../../../lib/meda/services/config/dynamic_config_service'

describe Meda::DynamicConfigService do

  let(:log_config) { {  'log_level' => 0 } }
  let(:config) { {'development' => log_config } }
  let(:meda_config_obj) { {} }

  describe '.config_changed?' do
    context 'when last modified time is the same as current modified time' do
      it "should return false" do
        timestamp = Time.now
        subject.last_modified_time = timestamp
        curr_modified_time = timestamp
        allow(File).to receive(:mtime).and_return(curr_modified_time)
        expect(subject.config_changed?).to eql(false)
      end
    end

    context 'when last modified time is different from current modified time' do
      it "should return true" do
        timestamp = Time.now
        subject.last_modified_time = timestamp
        curr_modified_time = timestamp - 1000
        allow(File).to receive(:mtime).and_return(curr_modified_time)
        expect(subject.config_changed?).to eql(true)
      end
    end
  end

  describe '.update_config' do
    it "should call get_update_configs" do
      allow(subject).to receive(:get_update_configs).and_return(meda_config_obj)
      expect(subject.update_config(meda_config_obj)).to eql(meda_config_obj)
      expect(subject).to have_received(:get_update_configs).with(meda_config_obj).once
    end
  end

  describe '.get_update_config' do
    it "should set meda configs log level"
  end
end