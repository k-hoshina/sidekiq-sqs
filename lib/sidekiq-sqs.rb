require 'active_support'
require 'aws-sdk'

require "sidekiq-sqs/version"
require 'sidekiq-sqs/manager'
require 'sidekiq-sqs/fetcher'
require 'sidekiq-sqs/client'
require 'sidekiq-sqs/processor'
require 'sidekiq-sqs/worker'
require 'sidekiq-sqs/aws-sdk/batch_send_failure_patch'

# TODO The retry server middleware directly writes to a retry zset.
# TODO Need a queue-prefix option to support multiple rails envs

module Sidekiq
  module Sqs
    module_function
    def enable!
      require 'sidekiq/manager'
      require 'sidekiq/fetch'
      require 'sidekiq/client'
      require 'sidekiq/processor'
      require 'sidekiq-sqs/util'

      Sidekiq::Manager.send :include, Sidekiq::Sqs::Manager
      Sidekiq::Fetcher.send :include, Sidekiq::Sqs::Fetcher
      Sidekiq::Client.send :include, Sidekiq::Sqs::Client
      Sidekiq::Processor.send :include, Sidekiq::Sqs::Processor
      Sidekiq::Worker::ClassMethods.send :include, Sidekiq::Sqs::Worker
      AWS::SQS::Queue.send :include, Sidekiq::Sqs::AwsSdk::BatchSendFailurePatch

      # Can't figure how to include/extend and not get a private method...
      def Sidekiq.sqs
        AWS::SQS.new
      end

      Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.remove Sidekiq::Middleware::Server::RetryJobs
          chain.remove Sidekiq::Middleware::Server::Timeout
        end
      end
    end
  end
end

