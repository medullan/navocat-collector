require_relative 'spec_helper'
require 'meda'

describe Meda::Hit do

  token = '3423432423423423423423'
  dataset = nil

	before(:all) do
    dataset = Meda::Dataset.new('test', Meda.configuration)
    Meda.datasets[token] = dataset
  end


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
        Meda::Hit.new(params, dataset)
      end

      context 'when profile_id is not blank' do
        it "should set user_id to profile_id" do
          expect(subject.as_ga[:user_id]).to eq(profile_id)
        end
      end
    end

    describe 'negative' do

      profile_id = ''
      client_id = '81ca294a8f7a46cebff36a54a3f811d3'

      let(:params) { {
            :time => DateTime.now,
            :profile_id => profile_id,
            :client_id => client_id,
            :props => {}
          } }

      subject do
        Meda::Hit.new(params, dataset)
      end

      context 'when profile_id is blank' do
        it "should keep user_id as nil" do
          expect(subject.as_ga[:user_id]).to be_nil
        end
      end
    end
  end
end