require 'uri'

class Cache
	def initialize(url)
		@uri = URI.parse(url)
		if @uri.scheme == 'local'
			@cache = CacheLocal.new(url)
		end
	end
	def fetch(url)
	end
end

class CacheLocal
	def initialize(path)
		@path = path
	end
	def alreadyexist?(url)
	end
	def write(url)
		folder = url.path.split('/')[0..-1].join('/')
		`mkdir -p #{@path}#{folder}`
		p `cd #{@path}#{folder} && curl -o url`
	end
end