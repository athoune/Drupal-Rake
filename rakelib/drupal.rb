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
			@drush = "#{`pwd`.strip}/bin/drush/drush"
		end
	end

	def major
		@version.split('.')[0..1].join('.')
	end
	
	def cron
		drush 'cron'
	end

	def clear_cache
		drush 'cc all', true
	end

	def test
		drush 'test mail'
	end
	
	def enable(m)
		drush "--yes enable #{m}"
	end
	
	def update
		drush "update"
	end
	
	def dl(m)
		drush "dl #{m}"
	end
	
	def updatedb
		drush "--yes updatedb"
	end

	private
	
	def drush(command, root=false)
		if File.exist? @path
			su = root ? "sudo":""
			sh "cd #{@path} && #{su} #{@drush} -u 1 #{command}"
		end
	end

end
