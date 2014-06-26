require 'java'

java_import 'java.util.concurrent.Executors'
java_import 'java.util.concurrent.TimeUnit'

java.util.concurrent.ThreadPoolExecutor.class_eval do
  java_alias :submit, :submit, [java.util.concurrent.Callable.java_class]
end

module Meda

  # Implements a simple jRuby interface to a FixedThreadPool from java.util.concurrent
  class WorkerPool
    def initialize(options={})
      pool_size = options[:size] || self.class.default_size
      @pool = java.util.concurrent.Executors.new_fixed_thread_pool(pool_size)
    end

    def self.default_size
      java.lang.Runtime.runtime.available_processors
    end

    def submit(&block)
      @pool.submit(block)
    end

    def active?
      @pool.getActiveCount > 0
    end

    def shutdown(wait=true)
      @pool.shutdown
    end

    def await_termination(options={})
      if options[:poll]
        until @pool.await_termination(options[:timeout] || 1, java.util.concurrent.TimeUnit::SECONDS)
          yield if block_given?
        end
      else
        @pool.await_termination(options[:timeout] || 300, java.util.concurrent.TimeUnit::SECONDS)
      end
    end
  end

end

