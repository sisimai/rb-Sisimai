require 'bundler/gem_helper'

if RUBY_PLATFORM =~ /java/
  filename = 'sisimai-java'
else
  filename = 'sisimai'
end
Bundler::GemHelper.install_tasks :name => filename

task :default => :test
task :test => [:publictest, :privatetest]
task :publictest do
  Dir.glob('./test/public/*-test.rb').each  { |cf| require cf }
end
task :privatetest do
  Dir.glob('./test/private/*-test.rb').each { |cf| require cf }
end

