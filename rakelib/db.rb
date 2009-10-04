class Db
	attr :uri
	
	def initialize(server, url)
		@uri = URI.parse(url)
		@bin = case server
			when 'mamp':    '/Applications/MAMP/Library/bin/'
			when 'macport': '/opt/local/bin'
			else            '/usr/bin'
		end
		@login, @password = @uri.userinfo.split(':')
		@dbname = @uri.path[1,@uri.path.length]
	end
	
	def dump(name)
		sh "mkdir -p dump"
		sh "#{@bin}mysqldump -u #{@login} -h #{@uri.host} --lock-tables --password='#{@password}' --quick --add-drop-database #{@dbname} | bzip2 -c > dump/#{name}.sql.bz2"
	end
	
	def load(name)
		sh "bzcat dump/#{name}.sql.bz2 | #{@bin}mysql -h #{@uri.host} -u #{@login} --password='#{@password}' #{@dbname}"
	end
end