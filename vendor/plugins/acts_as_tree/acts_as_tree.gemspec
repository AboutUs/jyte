spec = Gem::Specification.new do |s|
  s.name = 'acts_as_tree'
  s.version = '1.0.0'
  s.date = '10-10-2009'

  s.summary = 'Allows ActiveRecord Models to be easily structured as a tree'
  s.description = ''

  s.authors = ['Gabriel Sobrinho', 'David Heinemeier Hansson']
  s.email = 'gabriel.sobrinho@gmail.com'
  s.homepage = 'http://www.hite.com.br/'

  s.has_rdoc = true
  s.rdoc_options = ['--main', 'README']
  s.extra_rdoc_files = ['README']

  s.add_dependency 'rails', '>= 2.1'

  s.files = [
    'lib/active_record/acts/tree.rb',
    'acts_as_tree.gemspec',
    'init.rb',
    'Rakefile',
    'README'
  ]

  s.test_files = [
    'test/fixtures/mixin.rb',
    'test/fixtures/mixins.yml',
    'test/abstract_unit.rb',
    'test/acts_as_tree_test.rb',
    'test/database.yml',
    'test/schema.rb'
  ]
end

