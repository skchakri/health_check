# Copyright (c) 2010-2013 Ian Heggie, released under the MIT license.
# See MIT-LICENSE for details.

module HealthCheck
  class HealthCheckController < ActionController::Base

    layout false if self.respond_to? :layout

    def index
      checks = params[:checks] || 'standard'
      begin
        errors = HealthCheck::Utils.process_checks(checks)
      rescue Exception => e
        errors = e.message.blank? ? e.class.to_s : e.message.to_s
      end     
      if errors.blank?
        response.headers['Last-Modified'] = Time.now.httpdate
        obj = { :healthy => true, :message => HealthCheck.success }
        respond_to do |format|
          format.html { render :plain => HealthCheck.success }
          format.json { render :json => obj }
          format.xml { render :xml => obj }
          format.any { render :plain => HealthCheck.success }
        end
      else
        msg = "health_check failed: #{errors}"
        obj = { :healthy => false, :message => msg }
        respond_to do |format|
          format.html { render :plain => msg, :status => HealthCheck.http_status_for_error_text  }
          format.json { render :json => obj, :status => HealthCheck.http_status_for_error_object}
          format.xml { render :xml => obj, :status => HealthCheck.http_status_for_error_object }
          format.any { render :plain => msg, :status => HealthCheck.http_status_for_error_text  }
        end
        # Log a single line as some uptime checkers only record that it failed, not the text returned
        if logger
          logger.info msg
        end
      end
    end


    protected

    # turn cookies for CSRF off
    def protect_against_forgery?
      false
    end

  end
end
