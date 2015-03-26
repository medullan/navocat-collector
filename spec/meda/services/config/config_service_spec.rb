require_relative '../../../../lib/meda/services/config/dynamic_config_service'

describe Meda::DynamicConfigService.new(Meda.configuration) do

  let(:log_config) { {  'log_level' => 0 } }
  let(:config) { {'development' => log_config } }
  let(:meda_config_obj) { {} }

  describe '.timed_config_changed?' do
    context 'when current time is greater than next check time' do
      it "should call config_changed? and next_check_time" do
        allow(subject).to receive(:config_changed?)
        allow(subject).to receive(:next_check_time)
        allow(Time).to receive(:now).and_return(Time.new(2002, 1, 1, 0, 10, 1, "+00:00"))
        subject.next_check_time = Time.new(2002, 1, 1, 0, 10, 0, "+00:00")
        subject.timed_config_changed?
        expect(subject).to have_received(:config_changed?).once
        expect(subject).to have_received(:next_check_time).once
      end
    end

    context 'when current time is less than next check time' do
      it "should not call config_changed? and next_check_time" do
        allow(subject).to receive(:config_changed?)
        allow(subject).to receive(:next_check_time)
        allow(Time).to receive(:now).and_return(Time.new(2002, 1, 1, 0, 9, 0, "+00:00"))
        subject.next_check_time = Time.new(2002, 1, 1, 0, 10, 0, "+00:00")
        subject.timed_config_changed?
        expect(subject).to have_received(:config_changed?).exactly(0).times
        expect(subject).to have_received(:next_check_time).exactly(0).times
      end
    end
  end

  describe '.next_check_time' do
    it "should return time with seconds from now" do
      timestamp = Time.new(2002, 1, 1, 0, 0, 0, "+00:00")
      allow(Time).to receive(:now).and_return(timestamp)
      time = subject.next_check_time(600)
      new_time = Time.new(2002, 1, 1, 0, 10, 0, "+00:00")
      expect(time).to eql(new_time)
    end
  end

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
end