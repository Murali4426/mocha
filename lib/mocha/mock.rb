require 'mocha/expectation'
require 'mocha/stub'
require 'mocha/missing_expectation'
require 'mocha/metaclass'

module Mocha # :nodoc:

  # Traditional mock object.
  #
  # Methods return an Expectation which can be further modified by methods on Expectation.
  class Mock
    
    # :stopdoc:
    
    def initialize(stub_everything = false, name = nil)
      @stub_everything = stub_everything
      @mock_name = name
    end

    attr_reader :stub_everything
  
    def expectations
      @expectations ||= []
    end

    # :startdoc:

    # :call-seq: expects(method_name) -> expectation
    #            expects(method_names) -> last expectation
    #
    # Adds an expectation that a method identified by +method_name+ symbol must be called exactly once with any parameters.
    # Returns the new expectation which can be further modified by methods on Expectation.
    #   object = mock()
    #   object.expects(:method1)
    #   object.method1
    #   # no error raised
    #
    #   object = mock()
    #   object.expects(:method1)
    #   # error raised, because method1 not called exactly once
    # If +method_names+ is a +Hash+, an expectation will be set up for each entry using the key as +method_name+ and value as +return_value+.
    #   object = mock()
    #   object.expects(:method1 => :result1, :method2 => :result2)
    #
    #   # exactly equivalent to
    #
    #   object = mock()
    #   object.expects(:method1).returns(:result1)
    #   object.expects(:method2).returns(:result2)
    #
    # Aliased by <tt>\_\_expects\_\_</tt>
    def expects(method_names, backtrace = nil)
      method_names = method_names.is_a?(Hash) ? method_names : { method_names => nil }
      method_names.each do |method_name, return_value|
        expectations << Expectation.new(self, method_name, backtrace).returns(return_value)
        self.__metaclass__.send(:undef_method, method_name) if self.__metaclass__.method_defined?(method_name)
      end
      expectations.last
    end

    # :call-seq: stubs(method_name) -> expectation
    #            stubs(method_names) -> last expectation
    #
    # Adds an expectation that a method identified by +method_name+ symbol may be called any number of times with any parameters.
    # Returns the new expectation which can be further modified by methods on Expectation.
    #   object = mock()
    #   object.stubs(:method1)
    #   object.method1
    #   object.method1
    #   # no error raised
    # If +method_names+ is a +Hash+, an expectation will be set up for each entry using the key as +method_name+ and value as +return_value+.
    #   object = mock()
    #   object.stubs(:method1 => :result1, :method2 => :result2)
    #
    #   # exactly equivalent to
    #
    #   object = mock()
    #   object.stubs(:method1).returns(:result1)
    #   object.stubs(:method2).returns(:result2)
    #
    # Aliased by <tt>\_\_stubs\_\_</tt>
    def stubs(method_names, backtrace = nil)
      method_names = method_names.is_a?(Hash) ? method_names : { method_names => nil }
      method_names.each do |method_name, return_value|
        expectations << Stub.new(self, method_name, backtrace).returns(return_value)
        self.__metaclass__.send(:undef_method, method_name) if self.__metaclass__.method_defined?(method_name)
      end
      expectations.last
    end
    
    # :stopdoc:

    alias_method :__expects__, :expects

    alias_method :__stubs__, :stubs

    def method_missing(symbol, *arguments, &block)
      matching_expectation = matching_expectation(symbol, *arguments)
      if matching_expectation then
        matching_expectation.invoke(&block)
      elsif stub_everything then
        return
      else
        begin
          super_method_missing(symbol, *arguments, &block)
    		rescue NoMethodError
    			unexpected_method_called(symbol, *arguments)
    		end
  		end
  	end
  	
  	def respond_to?(symbol)
  	  expectations.any? { |expectation| expectation.method_name == symbol }
	  end
	
  	def super_method_missing(symbol, *arguments, &block)
  	  raise NoMethodError
    end

  	def unexpected_method_called(symbol, *arguments)
      MissingExpectation.new(self, symbol).with(*arguments).verify
    end
	
  	def matching_expectation(symbol, *arguments)
      expectations.reverse.detect { |expectation| expectation.match?(symbol, *arguments) }
    end
  
    def verify(&block)
      expectations.each { |expectation| expectation.verify(&block) }
    end
  
    def mocha_inspect
      address = self.__id__ * 2
      address += 0x100000000 if address < 0
      @mock_name ? "#<Mock:#{@mock_name}>" : "#<Mock:0x#{'%x' % address}>"
    end

    # :startdoc:

  end

end