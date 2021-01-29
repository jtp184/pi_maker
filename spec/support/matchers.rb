require 'rspec/expectations'

RSpec::Matchers.define(:be_a_filepath) do
  match { |mat| mat =~ %r{^(.+)/([^/]+)$} }
end
