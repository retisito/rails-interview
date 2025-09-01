module Api
  class BaseController < ApplicationController
    # Disable CSRF protection for API endpoints
    skip_before_action :verify_authenticity_token
  end
end
