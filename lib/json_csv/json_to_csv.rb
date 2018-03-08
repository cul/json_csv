require 'json'

module JsonCsv
  module JsonToCsv

    # Converts the given json_hash into a flat csv hash, converting all values to
    # strings (because CSVs are dumb and don't store info about data types)
    # Set first_index to 1 if you want the first element in an array to
    #
    def json_hash_to_flat_csv_row_hash(json_hash)
      flat = flatten_hash(json_hash)
      # Convert values to strings because in the CSV file, all values are strings
      flat.each { |key, val| flat[key] = val.nil? ? '' : val.to_s }
      flat
    end

    # This method calls itself recursively while flattening a hash, and during
    # this sequence of calls the obj param may either be a hash or an array.
    def flatten_hash(obj, parent_path = '', flat_hash_to_build = {})
      if obj.is_a?(Hash)
        obj.each do |key, val|
          if key_contains_unallowed_characters?(key)
            raise ArgumentError, 'Cannot deal with hash keys that contain "[" or "]" because these are used for internal processing.'
          end
          path = parent_path + (parent_path.empty? ? '' : '.') + key
          flatten_hash(val, path, flat_hash_to_build)
        end
      elsif obj.is_a?(Array)
        obj.each_with_index do |el, index|
          path = parent_path + "[#{index}]"
          flatten_hash(el, path, flat_hash_to_build)
        end
      else
        flat_hash_to_build[parent_path] = obj unless obj.nil? || obj == '' # ignore nil or empty string values
      end

      flat_hash_to_build
    end

    def key_contains_unallowed_characters?(key)
      return true if key.index('[') || key.index(']') || key.index('.')
      false
    end

  end
end
