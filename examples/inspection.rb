# Copy this into a Ruby file "inspection.rb", then:
#   ruby inspection.rb

require 'picky'

# Create an index which is saved into './index' when you
# run index.dump(). Note that :id is implied - every input
# object must supply an :id!
#
index = Picky::Index.new :people do
  category :age
  category :name
end

# Define a data input class. Any object that responds to
# :id, :age, :name can be added to the index.
#
Person = Struct.new :id, :age, :name

# Add some data objects to the index.
# IDs can be any unique string or integer.
#
index.add Person.new(1, 34, 'Florian is the author of picky')
index.add Person.new(2, 77, 'Floris is related to Florian')

# Look at pieces of the index.
#
puts index[:name].exact.inverted
puts index[:name].exact.weights
puts index[:name].partial.inverted
puts index[:name].partial.weights