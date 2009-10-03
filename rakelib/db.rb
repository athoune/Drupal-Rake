class Db
	attr :uri
	def initialize(server, url)
		@uri = URI.parse(url)
		@bin = case server
			when 'mamp':    '/Applications/MAMP/Library/bin/'
			when 'macport': '/opt/local/bin'
			else            '/usr/bin'
		end
		info = @uri.userinfo.split(':')
		@login = info[0]
		@password = info[1]
	end
	def dump(name)
		sh "mkdir -p dump"
		p @uri.userinfo
		sh "#{@bin}mysqldump -u #{@login} -h #{@uri.host} --lock-tables --password='#{@password}' --quick --add-drop-database #{@uri.path[1,@uri.path.length]} | bzip2 -c > dump/#{name}.sql.bz2"
	end
	def load(name)
		
	end
end