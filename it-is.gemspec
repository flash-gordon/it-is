# Provide a simple gemspec so you can easily use your
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name = 'it-is'
  s.version = '0.1.0'
  s.authors = ['Nikita Shilnikov']
  s.email = %w(fg@flashgordon.ru)
  s.homepage = 'http://github.com/flash-gordon/it-is'

  s.summary = 'Tiny gem for clean objects layering.'
  s.description = 'it-is allows you to link your ruby classes in a clean way with one-direction dependencies.'
  s.files = Dir['lib/**/*'] + %w(MIT-LICENSE README.md)

  s.add_dependency('activesupport', ['>= 3.2'])

  s.require_paths = %w(lib)
end
