# This file is a configuration file for a Rackup application.

# Load the service file found in the lib directory.
require './lib/service'

# This Sinatra web application was built in the Classic way. Which
# is great for simple web application. Sinatra automatically provides
# a class you can provide to Rackup's `run` method to start the
# application.
#
# Read about the 'Modular vs. Classic Style' in the Sinatra README.
# @see http://www.sinatrarb.com/intro.html
run ExampleApp
