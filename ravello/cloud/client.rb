require 'httparty'

class Ravello

	include HTTParty

	base_uri 'https://cloud.ravellosystems.com'

	def hello
		self.class.get '/services/hello'
	end

end