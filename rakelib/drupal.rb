class Drupal
	attr :version

	def initialize(path)
		@path = path
		Dir.chdir @path do
			@version = IO.read('modules/system/system.module').scan(/define\('VERSION', '(.*)'\);/)[0][0]
		end
	end

	def major
		@version.split('.')[0..1].join('.')
	end
	
	def drush(command)
		drush = `pwd`.strip + '/bin/drush/drush'
		Dir.chdir @path do
			sh "#{drush} #{command}"
		end
	end

	def cron
		self.drush 'cron'
	end

	def clear_cache
		self.drush 'clear cache'
	end

	def test
		self.drush 'test'
	end
end