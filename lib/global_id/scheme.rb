require 'uri/generic'
require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/object/blank'

module URI
  # The GlobalID URI scheme
  #
  class GlobalID < Generic

    # An Array of the available components for URI::GlobalID
    #
    COMPONENT = [ :scheme, :app, :model_name, :model_id ].freeze

    # A Regexp to match on the URI's path to get :model_name and :model_id out
    # of it
    #
    PATH_REGEXP = %r(\A/([^/]+)/?([^/]+)?\z)

    # A String that represents the scheme component for GlobalID URIs
    #
    SCHEME = 'gid'

    # Returns the app component of the URI.
    #
    #   URI("gid://bcx/Person/1234").app #=> "bcx"
    #
    attr_reader :app

    # Returns the model_name component of the URI.
    #
    #   URI("gid://bcx/Person/1234").model_name #=> "Person"
    #
    attr_reader :model_name

    # Returns the model_name component of the URI.
    #
    #   URI("gid://bcx/Person/1234").model_id #=> "1234"
    #
    attr_reader :model_id

    # If the value passed as an argument is invalid ArgumentError will be raised
    # otherwise the value that would be assigned to app is returned
    #
    #   URI::GlobalID.validate_app(nil) #=> ArgumentError
    #   URI::GlobalID.validate_app('foo/bar') #=> ArgumentError
    #
    #   URI::GlobalID.validate_app('foo-bar') #=> 'foo-bar'
    #   URI::GlobalID.validate_app('foo@bar') #=> 'bar'
    #
    def self.validate_app(value)
      parse("gid://#{value}/Person/1234").app
    rescue URI::InvalidComponentError, URI::InvalidURIError
      raise ArgumentError, 'Invalid app name. App names must be valid URI '\
                           'hostnames: alphanumeric and hypen characters only.'
    end

    # Returns an instance of URI::GlobalID created from the :app and :model
    # passed as arguments
    #
    #   app = 'bcx'
    #   person = Person.create(id: 1234)
    #   URI::GlobalID.create('bcx', person) #=> #<URI::GlobalID:0x007ff0b5979138 URL:gid://bcx/Person/1234>
    #
    def self.create(app, model)
      parse("gid://#{app}/#{model.class.name}/#{model.id}")
    end

    # Returns a URI::GlobalID instance from the String passed as an argument
    #
    #   URI::GlobalID.parse('gid://bcx/Person/1234) #=> #<URI::GlobalID:0x007ff0b5979138 URL:gid://bcx/Person/1234>
    #
    def self.parse(uri)
      uri_components = URI.split(uri)
      build(*uri_components)
    end

    # Creates a new URI::GlobalID instance from components of URI::Generic
    # with check. Generic components are: scheme, userinfo, host, port,
    # registry, path, opaque, query and fragment
    #
    def self.build(*args)
      args << nil   # parser
      args << true  # arg_check

      new(*args)
    end

    # Creates a new URI::Generic instance from generic components without check
    #
    def initialize(*args)
      @arg_check = args[10]
      args[10] = validate_components?

      super(*args)

      _, model_name, model_id = *(@path.match(PATH_REGEXP))

      self.app = @host
      self.model_name = model_name
      self.model_id = model_id
    end

    # Public setter for app component with check. When the String passed as an
    # argument is invalid it can raise URI::InvalidURIError or
    # URI::InvalidComponentError
    #
    #   gid = URI::GlobalID.parse('gid://bcx/Person/1234')
    #   gid.app = 'app' #=>  "app"
    #
    def app=(value)
      validate_component(value) if validate_components?
      check_host(value) if validate_components?
      @app = value
    end

    # Public setter for model_name component with check. When the String
    # passed as an argument is invalid it raises URI::InvalidComponentError
    #
    #   gid = URI::GlobalID.parse('gid://bcx/Person/1234')
    #   gid.model_name = 'Person' #=>  "Person"
    #
    def model_name=(value)
      validate_component(value) if validate_components?
      @model_name = value
    end

    # Public setter for model_id component with check. When the String passed
    # as an argument is invalid it raises URI::InvalidComponentError
    #
    #   gid = URI::GlobalID.parse('gid://bcx/Person/1234')
    #   gid.model_id = '1234' #=>  "1234"
    #
    def model_id=(value)
      validate_component(value) if validate_components?
      @model_id = value
    end

    # Returns a String representation of URI::GlobalID
    #
    #   app = 'bcx'
    #   person = Person.create(id: 1234)
    #   gid = URI::GlobalID.create('bcx', person)
    #   gid.to_s #=> "gid://bcx/Person/1234"
    #
    def to_s
      "#{SCHEME}://#{app}/#{model_name}/#{model_id}"
    end

    private

      def validate_components?
        @arg_check.nil? ? true : @arg_check
      end

      def validate_component(component)
        if component.blank?
          raise URI::InvalidComponentError,
                "Expected a URI like #{SCHEME}://app/Person/1234: #{self.inspect}"
        end
      end

      def check_scheme(value)
        super(value)

        if value != SCHEME
          raise URI::BadURIError, "Not a #{SCHEME}:// URI scheme: #{self.inspect}"
        end
      end
  end

  @@schemes['GID'] =  GlobalID
end
