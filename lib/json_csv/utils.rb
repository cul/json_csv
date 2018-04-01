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

    def self.recursively_remove_blank_fields!(hash_or_array)
      return if hash_or_array.frozen? # We can't modify a frozen value, so we won't.

      if hash_or_array.is_a?(Array)
        # Recurse through non-empty elements
        hash_or_array.each do |element|
          recursively_remove_blank_fields!(element) if element.is_a?(Hash) || element.is_a?(Array)
        end

        # Delete blank array element values on this array level (including empty object ({}) values)
        hash_or_array.delete_if do |element|
          removable_value?(element)
        end
      elsif hash_or_array.is_a?(Hash)
        hash_or_array.each_value do |value|
          recursively_remove_blank_fields!(value) if value.is_a?(Hash) || value.is_a?(Array)
        end

        # Delete blank hash values on this hash level (including empty object ({}) values)
        hash_or_array.delete_if do |_key, value|
          removable_value?(value)
        end
      else
        raise ArgumentError, 'Must supply a hash or array.'
      end

      hash_or_array
    end

    # Recursively goes through an object and strips whitespace,
    # modifying the object's nested child hashes or array.
    # Note: This method modifies hash values, but does not
    # modify hash keys.
    def self.recursively_strip_value_whitespace!(obj)
      if obj.is_a?(Array)
        obj.each do |element|
          recursively_strip_value_whitespace!(element)
        end
      elsif obj.is_a?(Hash)
        obj.each_value do |value|
          recursively_strip_value_whitespace!(value)
        end
      elsif obj.is_a?(String)
        obj.strip!
      end

      obj
    end

  end
end
