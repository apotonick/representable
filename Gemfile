source 'https://rubygems.org'

gemspec

platform :mri do
  gem "ruby-prof"
end

platform :rbx do
  gem "psych"
  gem "rubysl-irb"
  gem "json_pure"
end

group :test do
  gem "nokogiri", require: false
  gem "multi_json", require: false
end
