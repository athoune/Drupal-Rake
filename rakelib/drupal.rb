class Drupal
	attr :version

	def initialize(server, path)
		@php = Php.new server
		@path = path
		if File.exist? path
			Dir.chdir @path do
				@version = IO.read('modules/system/system.module').scan(/define\('VERSION', '(.*)'\);/)[0][0]
			end
		else
			@version = nil
		end
		@drush = "#{@php.php} #{`pwd`.strip}/bin/drush/drush.php -r ."
	end

	def major
		@version.split('.')[0..1].join('.')
	end
	
	def drush(command)
		Dir.chdir @path do
			p @path
			sh "#{@drush} #{command}"
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
		self.drush "updatedb"
	end
end