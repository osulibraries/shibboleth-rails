module Shibboleth::Rails

  module ModelAdditions
    def authenticated_by_shibboleth
      extend ClassMethods
      include InstanceMethods
    end

    module ClassMethods
      def find_or_create_from_shibboleth(identity)
        affiliations = identity.delete(:affiliations)

        unless find_by_emplid(identity[:emplid])
          user = find_by_name_n_and_emplid(identity[:name_n], nil)
          if user
            user.update_attribute(:emplid, identity[:emplid])
            user.save
          end
        end
        user = find_or_create_by_emplid(identity)


        identity.each do |key, value|
          if user.respond_to?(key) and user.send(key).nil?
            user.update_attribute(key.to_sym, value)
          end
        end

        # names change due to marriage, etc.
        # update_attribute is a NOOP if not different
        # user.update_attribute(:name_n, identity[:name_n])
        # user.update_role(affiliations) if user.respond_to?(:update_role)
        user
      end
    end

    module InstanceMethods
      def update_usage_stats(request, args = {})
        if args[:login]
          if self.respond_to?(:login_count)
            self.login_count ||= 0
            self.login_count  += 1
          end

          if self.respond_to?(:current_login_at)
            self.last_login_at = self.current_login_at if self.respond_to?(:last_login_at)
            self.current_login_at = Time.now
          end

          if self.respond_to?(:current_login_ip)
            self.last_login_ip = self.current_login_ip if self.respond_to?(:last_login_ip)
            self.current_login_ip = request.remote_ip
          end

          self.login_callback(request, args) if self.respond_to?(:login_callback)
        end
        self.last_request_at = Time.now if self.respond_to?(:last_request_at)

        save(:validate => false)

        self.request_callback(request, args) if self.respond_to?(:request_callback)
      end
    end

  end
end

::ActiveRecord::Base.send :extend, Shibboleth::Rails::ModelAdditions
