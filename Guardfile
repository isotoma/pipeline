guard 'bundler' do
  watch('Gemfile')
  watch('pipeline.gemspec')
end

# Add
#   :cli => '-t focus'
# to focus specs

guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }

  # String watch patterns are matched with simple '=='
  watch('spec/spec_helper.rb') { "spec" }
end

