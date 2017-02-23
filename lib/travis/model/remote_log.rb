require 'virtus'

class RemoteLog
  class << self
    def find_by_job_id(job_id)
      logs_api.find_by_job_id(job_id)
    end

    def write_content_for_job_id(job_id, content: '')
      logs_api.write_content_for_job_id(job_id, content: content)
    end

    private def logs_api
      @logs_api ||= Travis::LogsApi.new(
        url: Travis.config.logs_api.url,
        auth_token: Travis.config.logs_api.auth_token
      )
    end
  end

  include Virtus.model(nullify_blank: true)

  attribute :aggregated_at, Time
  attribute :archive_verified, Boolean, default: false
  attribute :archived_at, Time
  attribute :archiving, Boolean, default: false
  attribute :content, String
  attribute :created_at, Time
  attribute :id, Integer
  attribute :job_id, Integer
  attribute :purged_at, Time
  attribute :removed_at, Time
  attribute :removed_by_id, Integer
  attribute :updated_at, Time

  def job
    @job ||= Job.find(job_id)
  end

  def removed_by
    return nil unless removed_by_id
    @removed_by ||= User.find(removed_by_id)
  end

  def parts
    # The content field is always pre-aggregated.
    []
  end

  alias log_parts parts

  def aggregated?
    !!aggregated_at
  end

  def clear!(user = nil)
    message = ''
    message = "Log removed by #{user.name} at #{Time.now.utc}" if user
    self.class.write_content_for_job_id(job_id, content: message)
    message
  end

  def archived?
    archived_at && archive_verified?
  end

  def to_json
    {
      'log' => attributes.slice(
        *%i(id content created_at job_id updated_at)
      )
    }.to_json
  end
end
