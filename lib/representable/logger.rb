# Provides really basic logging functionality.
# You should include it on your class.
#
#     class MyClass
#       include Representable::Logger
#
#       def my_method
#         log "something"
#       end
#     end
#
# Or you can use the class methods.
#
#   logger = Representable::Logger
#   logger.log("something")
#
# You can turn logging on or off with:
#   Representable::Logger.on!
#   Representable::Logger.off!
#
# And check for the current logging state with:
#   Representable::Logger.on?
#   Representable::Logger.off?
#
# The default logging state is *on!*.
#
# At tests, we have disabled logging to not polute tests output.
# But you can enable it at the command line with:
#
#   DEBUG=true bundle exec rake
#
# {Representable::Debug}, {Representable::Debug::Binding} and
# {Representable::Pipeline::Debug} uses {Representable::Logger} for output.
# So you can turn on and off these classe's output manipulating
# {Representable::Logger} state.

module Representable::Logger

  # @example
  #   logger = Representable::Logger
  #   logger.log("something")
  #
  # @param args [String]
  # @return [nil]
  def self.log(*args)
    puts args if Representable::Logger.on?
  end

  # @example
  #   class MyClass
  #     include Representable::Logger
  #
  #     def my_method
  #       log "something"
  #     end
  #   end
  def log(*args)
    Representable::Logger.log(args)
  end

  # Check if logging is enabled.
  def self.on?
    @logging
  end

  # Check if logging is disabled.
  def self.off?
    !on?
  end

  # Turns on logger.
  # Any {#log} call will be outputed to STDOUT.
  #
  # @return [Boolean]
  def self.on!
    @logging = true
  end

  # Turns off logger.
  # Any {#log} call will be discarded.
  #
  # @return [Boolean]
  def self.off!
    @logging = false
  end

  on! # default state
end