class Drupal
	def initialize(path)
		@path = path
	end
	def version
		Dir.chdir @path do
			IO.read('modules/system/system.module').scan(/define\('VERSION', '(.*)'\);/)[0][0]
		end
	end
	def drush(command)
		drush = `pwd` + '/bin/drush/drush'
		Dir.chdir @path do
			sh "#{drush} #{command}"
		end
	end
end