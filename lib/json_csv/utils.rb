# frozen_string_literal: true

module JsonCsv
  module Utils
    # Returns true for empty strings, empty arrays, or empty hashes.
    # Also returns true for strings that only contain whitespace.
    # Returns false for all other values, including booleans and numbers.
    def self.removable_value?(value)
      return true if value.respond_to?(:empty?) && value.empty? # empty string, empty array, or empty hash
      return true if value.is_a?(String) && value.strip.empty? # string that only contains whitespace
      return true if value.nil?

      false
    end

    def self.hash_or_array?(obj)
      obj.is_a?(Hash) || obj.is_a?(Array)
    end

    # Given a Hash or Array, recursively removes all blank fields.
    # Note: This method will raise an ArgumentError if the supplied object
    # is a frozen Hash or Array.
    def self.recursively_remove_blank_fields!(hash_or_array)
      raise ArgumentError, 'Must supply a Hash or Array' unless hash_or_array?(hash_or_array)
      raise ArgumentError, "Cannot modify frozen value: #{hash_or_array.inspect}" if hash_or_array.frozen?

      case hash_or_array
      when Array
        # Recurse through non-empty elements
        hash_or_array.each do |element|
          recursively_remove_blank_fields!(element) if hash_or_array?(element)
        end

        # Delete blank array element values on this array level (including empty object ({}) values)
        hash_or_array.delete_if do |element|
          removable_value?(element)
        end
      when Hash
        hash_or_array.each_value do |value|
          recursively_remove_blank_fields!(value) if hash_or_array?(value)
        end

        # Delete blank hash values on this hash level (including empty object ({}) values)
        hash_or_array.delete_if do |_key, value|
          removable_value?(value)
        end
      end

      hash_or_array
    end

    # Recursively goes through an object and strips whitespace,
    # modifying the object's nested child hashes or array.
    # Note: This method modifies hash values, but does not
    # modify hash keys.
    def self.recursively_strip_value_whitespace!(obj, replace_frozen_strings_when_stripped: false)
      case obj
      when Array
        obj.each_with_index do |element, ix|
          if element.is_a?(String) && replace_frozen_strings_when_stripped
            stripped_string = element.strip
            obj[ix] = stripped_string if stripped_string != obj[ix]
          else
            recursively_strip_value_whitespace!(
              element,
              replace_frozen_strings_when_stripped: replace_frozen_strings_when_stripped
            )
          end
        end
      when Hash
        obj.each do |key, value|
          if value.is_a?(String) && replace_frozen_strings_when_stripped
            stripped_string = obj[key].strip
            obj[key] = stripped_string if stripped_string != obj[key]
          else
            recursively_strip_value_whitespace!(
              value,
              replace_frozen_strings_when_stripped: replace_frozen_strings_when_stripped
            )
          end
        end
      when String
        obj.strip!
      end

      obj
    end
  end
end
