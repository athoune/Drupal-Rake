class Drupal
	attr :version

	def initialize(server, path, user=1)
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
		@drush = "#{@php.php} ./bin/drush/drush.php "
		@user = user
	end

	def major
		@version.split('.')[0..1].join('.')
	end
	
	def cron
		drush 'cron ; true'
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
		drush "pm-update"
	end
	
	def dl(m)
		drush "dl #{m}"
	end
	
	def updatedb
		drush "--yes updatedb"
	end

	def vset(key, value)
		drush "--yes vset #{key} \"#{value}\""
	end
	
	def vget(key)
		drush "vget #{key}"
	end

	def vdel(key)
		drush "vdel #{key}"
	end

	private
	
	def drush(command, root=false)
		if File.exist? @path
			su = root ? "sudo":""
			sh "#{su} #{@drush} --root=#{@path} --user=#{@user} #{command}"
		end
	end

end
