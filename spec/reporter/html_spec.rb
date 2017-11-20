# frozen_string_literal: true

require 'spec_helper'
require 'deep_cover/reporter/html'

module DeepCover
  module Reporter
    RSpec.describe HTML do
      let(:coverage) { trivial_gem_coverage }

      describe HTML::Site do
        let(:site) { HTML::Site.new(coverage.covered_codes) }
        it 'renders the index' do
          html = site.render_index
          html.should include '"header":"Nodes"'
        end
        it 'renders the sources' do
          html = site.render_source(coverage.covered_codes.first)
          html.should include 'title="potentially_executable">13</span>'
        end
      end

      describe HTML::Index do
        let(:index) { HTML::Index.new(coverage.analysis) }
        it {
          data = index.stats_to_data
          children = data.first.delete(:children)
          data.should ==
            [{text: 'cli_fixtures/trivial_gem/lib',
              data: {per_char: {executed: 109, not_executed: 8, not_executable: 51, ignored: 0},
                     branch: {executed: 0, not_executed: 0, not_executable: 0, ignored: 0},
                     node: {executed: 13, not_executed: 2, not_executable: 0, ignored: 2},
                     per_char_percent: 93.16,
                     branch_percent: 100,
                     node_percent: 88.24,
              },
              state: {opened: true},
              },
            ]
          children.size.should == 2
          children.first.should ==
            {text: '<a href="cli_fixtures/trivial_gem/lib/trivial_gem.rb.html">cli_fixtures/trivial_gem/lib/trivial_gem.rb</a>',
             data: {per_char: {executed: 78, not_executed: 8, not_executable: 40, ignored: 0},
                    branch: {executed: 0, not_executed: 0, not_executable: 0, ignored: 0},
                    node: {executed: 9, not_executed: 2, not_executable: 0, ignored: 2},
                    per_char_percent: 90.7,
                    branch_percent: 100,
                    node_percent: 84.62,
                  },
            }
        }
      end

      describe HTML::Tree do
        include HTML::Tree
        it { path_to_partial_paths('a/b/c').should == %w[a a/b a/b/c] }
        it { list_to_twig(%i[a b c]).should == {a: {b: {c: {}}}} }
        it {
          deep_merge([{a: {b: {c: {}}}},
                      {a: {b: {d: {}}}},
                     ]).should ==
            {a: {b: {c: {}, d: {}}}}
        }
        it {
          simplify(a: {b: {c: {}, d: {}}}).should ==
            {b: {c: {}, d: {}}}
        }

        let(:paths) { %w[abcd xyz abcef abceg abch].map { |s| s.split('').join('/') } }
        it {
          paths_to_tree(paths).should == {
                                           'a/b/c' => {'a/b/c/d' => {}, 'a/b/c/e' => {'a/b/c/e/f' => {}, 'a/b/c/e/g' => {}}, 'a/b/c/h' => {}},
                                           'x/y/z' => {},
                                         }
        }
      end
    end
  end
end
