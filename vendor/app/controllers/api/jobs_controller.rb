module Api
  class JobsController < BaseController
    # GET /api/jobs/stats
    def stats
      stats = AutoCompletionService.get_job_stats
      
      render json: {
        sidekiq_stats: stats,
        timestamp: Time.current,
        server_info: {
          rails_env: Rails.env,
          sidekiq_version: Sidekiq::VERSION
        }
      }
    end

    # POST /api/jobs/cancel/:todo_list_id
    def cancel
      todo_list_id = params[:todo_list_id]
      result = AutoCompletionService.cancel_scheduled_jobs(todo_list_id)
      
      render json: {
        message: "Cancellation request processed",
        todo_list_id: todo_list_id,
        details: result
      }
    end

    # GET /api/jobs/queues
    def queues
      queue_stats = Sidekiq::Queue.all.map do |queue|
        {
          name: queue.name,
          size: queue.size,
          latency: queue.latency
        }
      end

      render json: {
        queues: queue_stats,
        total_jobs: queue_stats.sum { |q| q[:size] }
      }
    end
  end
end
