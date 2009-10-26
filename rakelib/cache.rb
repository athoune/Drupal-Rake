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
	def flaturl(url)
		"#{url.host}#{self.folder(url)}"
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
		f = "#{@path.path}#{self.flaturl(url)}"
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