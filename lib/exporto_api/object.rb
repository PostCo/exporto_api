# frozen_string_literal: true

require "ostruct"
require "active_support/core_ext/string/inflections"

module ExportoAPI
  class Base < OpenStruct
    attr_reader :original_response

    def initialize(attributes)
      @original_response = immutable_copy(attributes)
      super(to_ostruct(@original_response))
    end

    def to_hash
      ostruct_to_hash(self)
    end

    alias_method :to_h, :to_hash

    def raw
      @original_response
    end

    private

    def to_ostruct(object)
      case object
      when Hash
        OpenStruct.new(
          object.transform_keys { |key| key.to_s.underscore }
            .transform_values { |value| to_ostruct(value) }
        )
      when Array
        object.map { |value| to_ostruct(value) }
      else
        object
      end
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
        duplicate(value)
      end

      copy.freeze
    end

    def duplicate(value)
      value.dup
    rescue TypeError
      value
    end

    def ostruct_to_hash(object)
      case object
      when OpenStruct
        object.each_pair.to_h
          .transform_keys(&:to_s)
          .transform_values { |value| ostruct_to_hash(value) }
      when Array
        object.map { |value| ostruct_to_hash(value) }
      when Hash
        object.transform_keys(&:to_s)
          .transform_values { |value| ostruct_to_hash(value) }
      else
        object
      end
    end
  end
end
