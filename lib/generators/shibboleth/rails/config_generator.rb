module Shibboleth::Rails
  module Generators
      class ConfigGenerator < Rails::Generators::Base
        desc 'Creates a shibboleth-rails gem configuration file at config/shibboleth.yml, and an initializer at config/initializers/shibboleth.rb'

        def self.source_root
          File.expand_path("../templates", __FILE__)
        end


        def create_config_file
          template 'shibboleth.yml', File.join('config', 'shibboleth.yml')
        end


        def create_initializer_file
          template 'initializer.rb', File.join('config', 'initializers', 'shibboleth.rb')
        end
      end
    end
end