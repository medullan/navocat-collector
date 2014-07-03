require 'csv'
require 'descriptive-statistics'

module JtlAnalyze

  SUMMARY = 'Summary'

  class Subject
    attr_reader :path, :times, :successes, :failures

    def initialize(path)
      @path = path
      @times = []
      @hits = 0
      @successes = 0
      @failures = 0
    end

    def add_response(status_code, time)
      if status_code >= 200 && status_code < 400
        @hits += 1
        @times << time
        @successes += 1
      elsif status_code >= 400
        @hits += 1
        @times << time
        @failures += 1
      end
    end

    def formatted_statistics
      stats = DescriptiveStatistics::Stats.new(@times)
      trans_rate = (@times.length / (stats.sum * 0.001)).round(2)

      "Total hits = #{@hits}\n" +
        "Successful responses = #{@successes}\n" +
        "Error responses = #{@failures}\n" +
        "Mean response time = #{stats.mean.to_i} ms\n" +
        "Transaction rate = #{trans_rate} trans/sec\n" +
        "50% response time = #{stats.value_from_percentile(50)} ms\n" +
        "90% response time = #{stats.value_from_percentile(90)} ms\n"
    end
  end

  class Analysis
    attr_reader :file_path, :subjects, :summary

    def initialize(file_path)
      @file_path = file_path
      @subjects = {}
      @summary = Subject.new(SUMMARY)
    end

    def analyze!
      CSV.foreach(file_path, csv_options) do |row|
        analyze_row(row)
      end
      self
    end

    def subjects
      @subjects.values
    end

    protected

    def analyze_row(row)
      time = row[1].to_i
      path = row[2]
      status_code = row[3].to_i
      subject = subject_for_path(path)
      subject.add_response(status_code, time)
      summary.add_response(status_code, time)
      true
    end

    def subject_for_path(path)
      if @subjects[path].nil?
        @subjects[path] = Subject.new(path)
      end
      @subjects[path]
    end

    def csv_options
      { :col_sep => '|' }
    end

  end
end

