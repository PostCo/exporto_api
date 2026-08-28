# frozen_string_literal: true

require "active_support/inflector/methods"

module ExportoAPI
  class Object
    attr_reader :raw
    alias original_response raw

    def initialize(attributes = {})
      unless attributes.respond_to?(:each_pair)
        raise ArgumentError, "attributes must be a hash-like object"
      end

      @raw = immutable_copy(attributes)
      @attributes = transform_hash(@raw).freeze
    end

    def [](key)
      attributes[normalize_key(key)]
    end

    def method_missing(name, *arguments, &block)
      if arguments.empty? && block.nil? && attributes.key?(name)
        attributes.fetch(name)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      attributes.key?(name) || super
    end

    private

    attr_reader :attributes

    def transform_hash(hash)
      hash.each_pair.with_object({}) do |(key, value), transformed|
        transformed[normalize_key(key)] = transform_value(value)
      end
    end

    def transform_value(value)
      case value
      when Hash
        self.class.new(value)
      when Array
        value.map { |entry| transform_value(entry) }.freeze
      else
        value
      end
    end

    def normalize_key(key)
      ActiveSupport::Inflector.underscore(key.to_s).to_sym
    end

    def immutable_copy(value)
      copy = case value
      when Hash
        value.each_pair.with_object({}) do |(key, entry), result|
          result[immutable_copy(key)] = immutable_copy(entry)
        end
      when Array
        value.map { |entry| immutable_copy(entry) }
      else
        begin
          value.dup
        rescue TypeError
          value
        end
      end

      copy.freeze
    end
  end
end
