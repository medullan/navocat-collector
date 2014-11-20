require_relative 'spec_helper'
require 'meda'


describe Meda::HitFilter do

  token = '3423432423423423423423'
  dataset = nil


  before(:all) do
    dataset = Meda::Dataset.new('test', Meda.configuration)
    dataset.token = token
    dataset.default_profile_id = '471bb8f0593711e48c1e44fb42fffeaa'
    dataset.landing_pages = [/\/pilot\/landingpage/,/\/members\/myblue\/dashboard/]
    dataset.whitelisted_urls  = [/\/hra\/lobby\.aspx\?toolid=3563/,/\/web\/guest\/myblue\?.*Fcreate_account$/,/\/web\/guest\/myblue\?.*Fcreate_account&_58_resume=$/]
    dataset.enable_data_retrivals = true
    dataset.google_analytics = {
      'record' => true,
      'tracking_id' => 'UA-666-1',
      'custom_dimensions' => { 'gender' => { 'mapping' => {
            'm' => 'male',
            'M' => 'male',
            'f' => 'female',
            'F' => 'female',
            'u' => 'unknown',
            'U' => 'unknown'
          }}
      }
    }
    Meda.datasets[token] = dataset
  end



  subject do
    Meda::HitFilter.new(dataset.google_analytics)
  end

  hit = nil
  token = '3423432423423423423423'
  request_path = "/web/guest/myblue?p_p_id=58&p_p_lifecycle=0&p_p_state=normal&p_p_mode=view&p_p_col_id=column-1&p_p_col_count=1&_58_struts_action=%2Flogin%2Fcreate_account"
  unknown_path = "/web/guest/myblue?p_p_id=58&p_p_lifecycle=0&p_p_state=normal&p_p_mode=view&p_p_col_id=column-1&p_p_col_count=1&_58_struts_action=%2Flogin%2Fcreate_account_random_ext"
  no_qa_params = "/web/guest/myblue"

  context 'with a hit' do
    let(:page_info) { {
          :profile_id => 'b6822676c73211e3aaf844fb42fffe8c',
          :time => DateTime.now,
          :client_id => 'c3032676c73211e3aaf844fb42fffe8c',
          :props =>  ActiveSupport::HashWithIndifferentAccess.new( {

              'user_ip'=>'127.0.0.0',
              'referrer'=>'',
              'user_language'=>'en-US,en;q=0.8',
              'user_agent'=>'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36',
              'cb'=>'d380a42a60a5df4ab6fafcc3f353cb853bc7',
              'hostname'=>'localhost',
              'path'=>'/sample.html',
              'title'=>'Awesome Page'
            } )

    }  }

    let(:profile) {
      ActiveSupport::HashWithIndifferentAccess.new({

          'id' => '381ec3c069a811e4a143782bcb0f409f',
          'gender' => 'f',
          'age' => '59',
          'health_status_and_consumer_segment' => 'Healthy and Engaged',
          'health_status_segement' => 'Healthy and Independent',
          'consumer_segment' => 'Fast Trackers',
          'plan_option' => 'Basic',
          'member_type' => 'O',
          'health_consumer_segement' => 'Fast Trackers'
      })
    }



    before(:each) do
      hit = nil
      #stub(subject.store).get_profile_by_id(profile_id) { profile_info }
      hit = Meda::Hit.new(page_info)
      hit.profile_props = profile
      subject.whitelisted_urls = dataset.whitelisted_urls
    end

    describe '#filter_age' do

      let(:age) { {
        :eg1 => '17',
        :eg2 => '18',
        :eg3 => '35',
        :eg4 => '44',
        :eg5 => '55',
        :eg6 => '64',
        :eg7 => '1000'
      } }

      it 'should provide age in a range' do
        hit.profile_props[:age] = '17'
        result_hit = subject.filter_age(hit)
        expect(result_hit.profile_props[:age]).to eq('<18')

        hit.profile_props[:age] = '18'
        result_hit = subject.filter_age(hit)
        expect(result_hit.profile_props[:age]).to eq('18-44')

        hit.profile_props[:age] = '35'
        result_hit = subject.filter_age(hit)
        expect(result_hit.profile_props[:age]).to eq('18-44')

        hit.profile_props[:age] = '44'
        result_hit = subject.filter_age(hit)
        expect(result_hit.profile_props[:age]).to eq('18-44')

        hit.profile_props[:age] = '55'
        result_hit = subject.filter_age(hit)
        expect(result_hit.profile_props[:age]).to eq('45-64')

        hit.profile_props[:age] = '64'
        result_hit = subject.filter_age(hit)
        expect(result_hit.profile_props[:age]).to eq('45-64')

        hit.profile_props[:age] = '1000'
        result_hit = subject.filter_age(hit)
        expect(result_hit.profile_props[:age]).to eq('65+')
      end


      # it 'should return an error for invalid age' do
      #   hit.profile_props[:age] = 'not an age'
      #   expect(subject.filter_age(hit)).to raise_error(StandardError)
      # end
    end

    describe '#filter_query_strings' do
      it 'only allows query stringed urls that are in a white-list' do
        #expect(subject.filter_profile_data(hit)).to eq(hit)

        hit.props[:path] = unknown_path
        result_hit = subject.filter_query_strings(hit)
        expect(result_hit.props[:path]).to eq('/web/guest/myblue')

        hit.props[:path] = request_path
        result_hit = subject.filter_query_strings(hit)
        expect(result_hit.props[:path]).to eq('/web/guest/myblue?p_p_id=58&p_p_lifecycle=0&p_p_state=normal&p_p_mode=view&p_p_col_id=column-1&p_p_col_count=1&_58_struts_action=%2Flogin%2Fcreate_account')

        hit.props[:path] = no_qa_params
        result_hit = subject.filter_query_strings(hit)
        expect(result_hit.props[:path]).to eq('/web/guest/myblue')

      end
    end



    describe '#filter_profile_data' do
      it 'should filter profile fields' do
        #expect(subject.filter_query_strings(hit)).to eq(hit)
      end
    end

    describe '#filter_hit' do
     it 'should be filtered' do
        #expect(subject).to receive(:filter_query_strings).with(hit)
        #subject.filter_hit(hit)
        #subject.should_receive(:filter_query_strings).with(hit)
        #subject.should_receive(:filter_profile_data).with(hit)
      end
    end


    describe '#filter_path' do
      it 'should return the path ' do
        hit.props[:path] = 'https://fepblue.org:8443/web/guest/myblue?p_p_id=58&p_p_lifecycle=0&p_p_state=normal&p_p_mode=view&p_p_col_id=column-1&p_p_col_count=1&_58_struts_action=%2Flogin%2Fcreate_account'
        result_hit = subject.filter_path(hit)
        expect(result_hit.props[:path]).to eq('/web/guest/myblue?p_p_id=58&p_p_lifecycle=0&p_p_state=normal&p_p_mode=view&p_p_col_id=column-1&p_p_col_count=1&_58_struts_action=%2Flogin%2Fcreate_account')
      end
    end


  end
end
