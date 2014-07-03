require 'rubygems'
require_relative 'jtl_analyze'

files = ARGV.map {|c| "perf/results/perf_test_#{c}_results.jtl"}

files.each do |file_path|
  puts "\nAnalyzing #{file_path}"
  analysis = JtlAnalyze::Analysis.new(file_path).analyze!

  analysis.subjects.each do |subject|
    puts "\n#{subject.path}\n---------------------"
    puts subject.formatted_statistics
  end

  puts puts "\nSummary\n---------------------"
  puts analysis.summary.formatted_statistics
end

