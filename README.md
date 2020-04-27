# json_csv

A pure-ruby library for converting deeply nested JSON structures to CSV...and back!

### Installation

```bash
gem install json_csv
```

### Usage

```ruby
require 'json_csv'

path_to_output_csv_file = '/path/to/file.csv'

# Write json-like hash objects to a csv file

JsonCsv.create_csv_for_json_records(path_to_output_csv_file) do |csv_builder|
  digital_objects_for_batch_export(batch_export) do |digital_object|
    csv_builder.add({...json-like hash...})
  end
end

# Read csv back into json-like hash objects

JsonCsv.csv_file_to_hierarchical_json_hash(csv_file.path) do |json_hash_for_row, csv_row_number|
  puts "Row: #{csv_row_number}" # prints out 2 the first time, then 3, etc.
  puts "Object: #{json_hash_for_row}" # prints out a hierarchical json object, created from the csv row
end
```

See specs for advanced usage.

### Running Tests (for developers):

Tests are great and we should run them.  Here's how:

```sh
bundle exec rake json_csv:ci
```
