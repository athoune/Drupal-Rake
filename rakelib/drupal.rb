class Drupal
	attr :version

	def initialize(server, path)
		@php = Php.new server
		@path = path
		if File.exist? "#{path}/modules/system/system.module"
			Dir.chdir @path do
				@version = IO.read('modules/system/system.module').scan(/define\('VERSION', '(.*)'\);/)[0][0]
			end
		else
			@version = nil
		end
		# --user 1
		# --root=.
		if `uname`.strip == 'Darwin'
			@drush = "#{@php.php} #{`pwd`.strip}/bin/drush/drush.php "
		else
			@drush = "#{`pwd`.strip}/bin/drush/drush -u 1"
		end
	end

	def major
		@version.split('.')[0..1].join('.')
	end
	
	def drush(command)
		if File.exist? @path
			Dir.chdir @path do
				p @path
				sh "#{@drush} #{command}"
			end
		end
	end

	def cron
		self.drush 'cron'
	end

	def clear_cache
		self.drush 'cache clear'
	end

	def test
		self.drush 'test mail'
	end
	
	def enable(m)
		self.drush "--yes enable #{m}"
	end
	
	def update
		self.drush "update"
	end
	
	def dl(m)
		self.drush "dl #{m}"
	end
	
	def updatedb
		self.drush "--yes updatedb"
	end
end
