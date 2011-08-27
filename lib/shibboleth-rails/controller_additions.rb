module Shibboleth::Rails

	module ControllerAdditions
		private

		def authenticated?
			request.env['employeeNumber'].present?
		end

		def shibboleth
			{:emplid => request.env['employeeNumber'],
			 :name_n => request.env['REMOTE_USER'].chomp("@osu.edu")}
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
			unless current_user
				if Rails.env.production?
					base = request.protocol + request.host
					requested_url = base + request.request_uri
					redirect_to [base, '/Shibboleth.sso/Login?target=',
						CGI.escape(requested_url)].join
				else
					redirect_to new_user_session_url, :notice => 'Login first, please.'
				end
			end
		end
	end

end

ActionController::Base.class_eval do
	include Shibboleth::Rails::ControllerAdditions
	helper_method :current_user
end