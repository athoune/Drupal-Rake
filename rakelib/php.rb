class Php
	attr_accessor :php, :pecl, :phpize
	#:phpini
	def initialize(server)
		@server = server
		@bin  = case server
			when "mamp": "/Applications/MAMP/bin/php5.2/bin/"
			when "macport": "/opt/local/bin/"
			when "fpm": "/opt/php-fpm/bin/"
			else "/usr/bin/"
		end
		@php    = @bin + 'php'
		@pecl   = @bin + 'pecl'
		@phpize = @bin + 'phpize'
	end
	def pecl?(packet)
		`#{@pecl} list`.split("\n")[3..-1].each do |line|
			if line.split(" ")[0] == packet
				return true
			end
		end
		return false
	end
end
