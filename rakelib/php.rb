class Php
	attr_accessor :php, :pecl, :phpize
	#:phpini
	def initialize(server)
		@server = server
		@bin  = case server
			when "mamp": "/Applications/MAMP/bin/php5/bin/"
			when "macport": "/opt/local/bin/"
			else "/usr/bin/"
		end
		@php    = @bin + 'php'
		@pecl   = @bin + 'pecl'
		@phpize = @bin + 'phpize'
	end
end