require 'rubygems'
require 'aws/s3'
require 'uri'
require 'rakelib/fetch'
require 'rakelib/cache'

include AWS::S3

class S3Cache < AbstractCache
	def initialize(url, local='file:///tmp/cache/s3')
		@uri = url
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
		S3Object.store self.s3path(url), File.new(@local.local(url), 'r'), @uri.host
	end
	
	def fetch(url)
		path = @local.local url
		if not self.alreadyexist? url
			self.write url
		end
		if @local.alreadyexist? url
			return path
		else
			@local.writeData url, S3Object.value(self.s3path(url), @uri.host)
		end
		return path
	end
end

Fetch.register 's3', S3Cache
