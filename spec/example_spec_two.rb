# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Metadata leak example spec two' do
  context 'metadata from another spec should not leak over' do
    it 'should not have metadata header hash' do |example|
      expect(example.metadata[:headers]).to eq(nil)
    end
  end
end
