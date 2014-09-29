module Shibboleth::Rails

  module ControllerAdditions
    private

    def authenticated?
      env_config_attribute('email').present?
    end

    def shibboleth
      shib = {:email       => env_config_attribute('email'),
       :name_n       => env_config_attribute('email').chomp("@osu.edu"),
       :affiliations => env_config_attribute('affiliations')}
      SHIBBOLETH_CONFIG['extra_attributes'].each do |name, value|
        shib[name.to_sym] = env_attribute(value)
      end
      return shib
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = if session[:simulate_id].present?
                        User.find(session[:simulate_id])
                      elsif authenticated?
                        User.find_or_create_from_shibboleth(shibboleth)
                      end
    end

    def require_shibboleth
      if current_user
        current_user.update_usage_stats(request, :login => session['new'])
        session.delete('new')
      else
        session['new'] = true
        session.delete(:simulate_id)
        if request.xhr?
          render :json => {:login_url => login_url}, :status => 401
        else
          redirect_to login_url
        end
      end
    end

    def requested_url
      if request.xhr?
        url_for :controller => 'root', :action => 'show', :xhr => 'true'
      elsif request.respond_to?(:url)
        request.url
      else
        request.protocol + request.host + request.request_uri
      end
    end

    def login_url
      if Rails.env.production? || Rails.env.staging?
        [request.protocol, request.host, '/Shibboleth.sso/Login?target=', CGI.escape(requested_url)].join
      else
        session['target'] = requested_url
        new_user_session_url
      end
    end

    def env_attribute(attr)
      request.env[attr] || request.env['HTTP_'+attr.upcase]
    end

    def env_config_attribute(name)
      attr = SHIBBOLETH_CONFIG['attributes'][name]
      env_attribute(attr)
    end

  endw

end

ActionController::Base.class_eval do
  include Shibboleth::Rails::ControllerAdditions
  helper_method :current_user
end
