# frozen_string_literal: true

require 'spec_helper'

begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"

  gem "rspec", "3.11.0"
end

puts "Ruby version is: #{RUBY_VERSION}"
require 'rspec/autorun'

RSpec.describe 'Metadata leak example spec' do
  describe 'nested describe', :headers => { :top => 'create hash here' } do
    before do |example|
      set_header(example, 'Describe-Before-Header', 'should exist for both contexts')
    end

    context 'example group 1' do
      before do |example|
        set_header(example, 'ExampleGroup1-Before-Header', 'example group 1 info')
      end

      it 'Foo - Has headers from all levels' do |example|
        set_header(example, 'foo', 'bar')
        expect(example.metadata[:headers]['foo']).to eq('bar')

        # These are set in parent example groups. Should exist
        expect(example.metadata[:headers][:top]).to eq('create hash here')
        expect(example.metadata[:headers]['Describe-Before-Header']).to eq('should exist for both contexts')
        expect(example.metadata[:headers]['ExampleGroup1-Before-Header']).to eq('example group 1 info')
      end

      example 'adjacent example should not have another example\'s metadata' do |example|
        expect(example.metadata[:headers]['foo']).to eq(nil)
      end

      context 'nested example group 1-1' do
        example 'validations' do |example|
          expect(example.metadata[:headers][:top]).to eq('create hash here')
          expect(example.metadata[:headers]['Describe-Before-Header']).to eq('should exist for both contexts')
          expect(example.metadata[:headers]['ExampleGroup1-Before-Header']).to eq('example group 1 info')

          # Should not have metadata set in another example
          expect(example.metadata[:headers]['foo']).to eq(nil)
        end
      end
    end

    context 'example group 2 is adjacent to example group 1' do
      example 'Baz - should not have metadata set in example group 1' do |example|
        set_header(example, 'baz', 'qux')
        expect(example.metadata[:headers]['baz']).to eq('qux')

        # These are set in parent example groups.
        expect(example.metadata[:headers][:top]).to eq('create hash here')
        expect(example.metadata[:headers]['Describe-Before-Header']).to eq('should exist for both contexts')

        # These are set in an adjacent context ('example group 1'). These metadata entries should not be available in this example.
        expect(example.metadata[:headers]['ExampleGroup1-Before-Header']).to eq(nil)
        expect(example.metadata[:headers]['foo']).to eq(nil)
      end
    end
  end

  describe 'nested describe 2' do
    it 'should not have a headers hash' do |example|
      expect(example.metadata[:headers]).to eq(nil)
    end
  end

  describe 'nested describe 3', :headers => { :top => 'create hash here' } do
    context 'only set metadata here, in an example group' do
      before do |example|
        set_header(example, 'corge', 'grault')
      end

      example 'do NOT set metadata in an example' do |example|
        expect(example.metadata[:headers][:top]).to eq('create hash here')
        expect(example.metadata[:headers]['corge']).to eq('grault')
      end
    end

    context 'adjacent example group' do
      it 'should not have metadata from adjacent example group' do |example|
        expect(example.metadata[:headers][:top]).to eq('create hash here')

        # Expect no metadata from adjacent context, but it is there
        expect(example.metadata[:headers]['corge']).to eq(nil)
      end
    end
  end
end
