require_relative 'spec_helper'
require 'meda'

describe Meda::Hit do

	


  describe '#as_ga' do

    describe 'positive' do

      profile_id = '83644ef0606511e48d5944fb42fffeaa'
      client_id = '81ca294a8f7a46cebff36a54a3f811d3'

      let(:params) { {
            :time => DateTime.now,
            :profile_id => profile_id,
            :client_id => client_id,
            :props => {}
          } }

      subject do
        Meda::Hit.new(params)
      end

      it 'appends user_id when profile_id is not default' do

        #puts subject.as_ga

        expect(subject.as_ga[:user_id]).to_not be_nil
        expect(subject.as_ga[:user_id]).to eq(profile_id)
        #expect(subject.as_ga).to be_true
      end
    end

    describe 'negative' do

      profile_id = '471bb8f0593711e48c1e44fb42fffeaa'
      client_id = '81ca294a8f7a46cebff36a54a3f811d3'

      let(:params) { {
            :time => DateTime.now,
            :profile_id => profile_id,
            :client_id => client_id,
            :props => {}
          } }

      subject do
        Meda::Hit.new(params)
      end

      

      it 'user_id not included when profile_id is default' do

        subject.default_profile_id = profile_id

        expect(subject.as_ga[:user_id]).to be_nil
        #expect(subject.as_ga).to be_true
      end
    end
  end
end