# frozen_string_literal: true

require 'spec_helper'

module DeepCover
  RSpec.describe 'CLI', :slow do
    describe 'The output of deep-cover' do
      let(:options) { '' }
      let(:command) { "exe/deep-cover spec/cli_fixtures/#{path} -o=false --reporter=istanbul --no-bundle #{options}" }
      let(:output) { Bundler.with_clean_env { `#{command}` } }
      subject { output }
      describe 'for a simple gem' do
        let(:path) { 'trivial_gem' }
        it do
          should =~ Regexp.new(%w[trivial_gem.rb 83.33 50 50].join('[ |]*'))
          should include '2 examples, 0 failures'
        end
      end

      describe 'for a single component gem like activesupport' do
        let(:path) { 'rails_like_gem/component_gem' }
        it do
          should =~ Regexp.new(%w[component_gem.rb 80 100 50].join('[ |]*'))
          should include '1 example, 0 failures'
          should_not include 'another_component'
        end
      end

      describe 'for a multiple component gem like rails' do
        let(:path) { 'rails_like_gem' }
        it do
          should =~ Regexp.new(%w[component_gem.rb 80 100 50].join('[ |]*'))
          should =~ Regexp.new(%w[foo.rb 100 100 100].join('[ |]*'))
          should include '1 example, 0 failures'
          should include 'another_component'
          should include '2 examples, 1 failure'
        end
      end

      describe 'for a rails app' do
        let(:options) { 'bundle exec rake' } # Bypass Spring
        let(:path) { 'simple_rails42_app' }
        it do
          should =~ Regexp.new(%w[dummy.rb 100 100 100].join('[ |]*'))
          should =~ Regexp.new(%w[user.rb 85.71 100 50].join('[ |]*'))
          should include '2 runs, 2 assertions, 0 failures, 0 errors, 0 skips'
        end
      end
    end

    it 'Can run `exe/deep-cover --version`' do
      'exe/deep-cover --version'.should run_successfully
    end
  end
end
