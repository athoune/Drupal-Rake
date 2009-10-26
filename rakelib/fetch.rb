require 'uri'
require 'cache'

module Fetch

	class Fetcher
		attr :uri
		def initialize(url = 'file:///tmp/fetcher/')
			@uri = URI.parse(url)
			if @uri.scheme == 'file'
				@cache = CacheLocal.new(@uri)
			end
		end
		def fetch(url)
			@cache.fetch(URI.parse(url))
		end
	end

	
end