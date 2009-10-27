require 'uri'
require 'rakelib/cache'

module Fetch
	@protocols = {'file' => CacheLocal}
	
	def Fetch.register name, clazz
		@protocols[name] = clazz
	end
	
	def Fetch.protocols
		@protocols
	end
	
	class Fetcher
		attr :uri
		def initialize(url = 'file:///tmp/fetcher/')
			@uri = URI.parse(url)
			@cache = Fetch.protocols[@uri.scheme].new(@uri)
		end
		def fetch(url)
			@cache.fetch(URI.parse(url))
		end
	end
	
end
