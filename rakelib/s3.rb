require 'rubygems'
require 'aws/s3'
require 'uri'
require 'rakelib/fetch'
require 'rakelib/cache'

include AWS::S3

class S3Cache < AbstractCache
	def initialize(url, local='file:///tmp/cache/s3')
		@uri = URI.parse(url)
		#AWS::S3::
		Base.establish_connection!(
			:access_key_id     => @uri.user,
			:secret_access_key => @uri.password
		)
		@local = CacheLocal.new URI.parse(local)
	end

	def s3path(url)
		"#{@uri.path}/#{url.host}#{url.path}"
	end

	def alreadyexist?(url)
		S3Object.exists? self.s3path(url), @uri.host
	end

	def write(url)
		@local.write url
		S3Object.store self.s3path(url), open(@local.local url), @uri.host
	end
	
	def fetch(url)
		if not self.alreadyexist? url
			return nil
		end
		#p @bucket.objects
		if not @local.alreadyexist? url
			open(@local.local(url), 'w') do |file|
				file.write S3Object.value(self.s3path(url), @uri.host)
			end
		end
		@local.local url
	end
end

Fetch.register 's3', S3Cache
