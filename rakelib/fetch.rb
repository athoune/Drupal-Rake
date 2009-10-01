require 'uri'

module Fetch

	class Fetcher
		def initialize(url = 'local:///tmp/fetcher/')
			@uri = URI.parse(url)
			if @uri.scheme == 'local'
				@cache = CacheLocal.new(@uri)
			end
		end
		def fetch(url)
			@cache.fetch(URI.parse(url))
		end
	end

	class AbstractCache
		def initialize(path)
			@path = path
		end
		def folder(url)
			url.path.split('/')[0..-2].join('/')
		end
		def file(url)
			url.path.split('/')[-1]
		end
	end

	class CacheLocal < AbstractCache 
		def local(url)
			"#{@path.path}#{url.host}#{url.path}"
		end
		def alreadyexist?(url)
			File.exist? self.local(url)
		end
		def write(url)
			f = "#{@path.path}#{url.host}#{self.folder(url)}"
			`mkdir -p #{f}`
			p `cd #{f} && curl -O "#{url.normalize}"`
		end
		#return local path
		def fetch(url)
			if not self.alreadyexist? url
				self.write url
			end
			self.local url
		end
	end
end