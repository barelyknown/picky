require 'spec'
require 'spec/rake/spectask'

task :default => :spec

desc "Run all specs in spec directory (excluding plugin specs)"
Spec::Rake::SpecTask.new(:spec) do |t|
  spec_root = File.join(File.dirname(__FILE__), '..', '..', 'spec')
  t.spec_opts = ['--options', "\"#{File.join(spec_root, 'spec.opts')}\""]
  t.spec_files = FileList[File.join(spec_root, '**', '*_spec.rb')]
end