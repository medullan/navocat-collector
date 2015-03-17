require_relative 'spec_helper'
require 'meda'

describe Meda::Dataset do
  subject do
    dataset = Meda::Dataset.new("test_#{rand(100000)}", Meda.configuration)

    token = '3423432423423423423423'
    member_id = '384739284793284293'

    dataset.token = token
    dataset.landing_pages = [/\/pilot\/landingpage/,/\/members\/myblue\/dashboard/]
    dataset.whitelisted_urls  = [/\/hra\/lobby\.aspx\?toolid=3563/,/\/web\/guest\/myblue\?.*Fcreate_account$/]
    dataset.enable_data_retrivals = true
    dataset.google_analytics = {
      'record' => true,
      'tracking_id' => 'UA-666-1',
      'custom_dimensions' => {}
    }
    Meda.datasets[token] = dataset

    dataset
  end





  describe '#store' do
    it 'exposes the profile datastore' do
      expect(subject.store).to be_present
    end
  end

  describe '#identify_profile' do
    it 'finds or creates the profile in the store' do
      info = {'foo' => 'bar'}
 #     mock(subject.store).find_or_create_profile(info)
      subject.identify_profile(info)
    end
  end

  context 'with a profile' do
    let(:profile_id) { 'b6822676c73211e3aaf844fb42fffe8c' }
    let(:profile_info) { ActiveSupport::HashWithIndifferentAccess.new({'state' => 'Maine'}) }

    before(:each) do
 #     stub(subject.store).get_profile_by_id(profile_id) { profile_info }
      allow(subject.store).to receive(:get_profile_by_id) { profile_info }
    end

    describe '#add_event' do
      let(:event_info) { {
        :profile_id => profile_id,
        :category => 'shop',
        :action => 'purchase'
      } }

      it 'adds the event to the dataset' do
        hit = subject.add_event(event_info)
        expect(hit.hit_type).to eq('event')
        expect(hit.time).to be_present
        expect(hit.profile_id).to eq(profile_id)
        expect(hit.props).to eq({:category => 'shop', :action => 'purchase', :user_id=>profile_id, :anonymize_ip=>1})
        expect(hit.profile_props).to eq(profile_info)
      end
    end

    describe '#add_pageview' do
      let(:pageview_info) { {
        :profile_id => profile_id,
        :hostname => 'example.com',
        :path => '/shopping/index.html',
        :title => 'Buy Stuff'
      } }

      it 'adds the event to the dataset' do
        hit = subject.add_pageview(pageview_info)
        expect(hit.hit_type).to eq('pageview')
        expect(hit.time).to be_present
        expect(hit.profile_id).to eq(profile_id)
        expect(hit.props).to eq({:hostname => 'example.com',
          :path => '/shopping/index.html', :title => 'Buy Stuff', :user_id=>profile_id, :anonymize_ip=>1})
        expect(hit.profile_props).to eq(profile_info)
      end
    end

    describe '#set_profile' do
      it 'adds the given attributes to the profile' do
        profile_id = '1234'
        info = {'foo' => 'bar'}
     #   mock(subject.store).set_profile(profile_id, info)
        allow(subject.store).to receive(:set_profile) { 3 }
        subject.set_profile(profile_id, info)
      end
    end

    describe '#stream_hit_to_disk' do
      let(:event_info) { {
        :profile_id => profile_id,
        :category => 'shop',
        :action => 'purchase'
      } }

      # TODO: Verify this info
      # {:hit=>#<struct Meda::Event time="2014-06-05T19:04:25-04:00", profile_id="b6822676c73211e3aaf844fb42fffe8c", props={:category=>"shop", :action=>"purchase"}>, :path=>"/Users/maxlord/repos/medullan/meda/data/test_1573/events/2014-06-05/2014-06-05-19:00:00-bd48a180ed0511e3824144fb42fffe8c.json", :data=>"{\"id\":\"bd696ff0ed0511e3824144fb42fffe8c\",\"ht\":\"2014-06-05T19:04:25-04:00\",\"hp\":{\"category\":\"shop\",\"action\":\"purchase\"},\"pi\":\"b6822676c73211e3aaf844fb42fffe8c\",\"pp\":{\"state\":\"Maine\"}}"}

      it 'streams the hit to the file on disk' do
        hit = subject.add_event(event_info)
        subject.stream_hit_to_disk(hit)
        expect(subject.last_disk_hit).to be_present
      end
    end

    describe '#stream_hit_to_ga' do
      let(:event_info) { {
        :profile_id => profile_id,
        :category => 'shop',
        :action => 'purchase'
      } }

      # TODO: Verify this info
      # {:hit=>#<struct Meda::Event time="2014-06-05T19:04:26-04:00", profile_id="b6822676c73211e3aaf844fb42fffe8c", props={:category=>"shop", :action=>"purchase"}>, :staccato_hit=>nil, :response=>nil}

      # WebMock and test HTTP call?

      it 'streams the hit to google analytics' do
        hit = subject.add_event(event_info)
        #subject.stream_hit_to_ga(hit)
      end
    end

  end
end

