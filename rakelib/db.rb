class Db
	attr :uri
	
	def initialize(server, url)
		@uri = URI.parse(url)
		@bin = case server
			when 'mamp':    '/Applications/MAMP/Library/bin/'
			when 'macport': '/opt/local/bin/'
			else            '/usr/bin/'
		end
		@login, @password = @uri.userinfo.split(':')
		@dbname = @uri.path[1,@uri.path.length]
	end
	
	def dump(name)
		sh "mkdir -p dump"
		sh %{  #{@bin}mysql -u #{@login} --password='#{@password}' -h #{@uri.host} --batch --execute "TRUNCATE #{@dbname}.sessions"; true}
		sh %{  #{@bin}mysql -u #{@login} --password='#{@password}' -h #{@uri.host} --batch --execute "TRUNCATE #{@dbname}.watchdog"; true}
		sh %{  #{@bin}mysql -u #{@login} --password='#{@password}' -h #{@uri.host} --batch --execute "TRUNCATE #{@dbname}.cache"; true}
		sh "#{@bin}mysqldump -u #{@login} -h #{@uri.host} --lock-tables --compact --password='#{@password}' --quick --add-drop-table  #{@dbname} | bzip2 -c > dump/#{name}.sql.bz2"
	end
	
	def load(name)
		if not File.exist? "dump/#{name}.sql.bz2"
			raise StandardError, "This dimp doesn't exist : dump/#{name}.sql.bz2"
		end
		sh "bzcat dump/#{name}.sql.bz2 | #{@bin}mysql -h #{@uri.host} -u #{@login} --password='#{@password}' #{@dbname}"
	end
	
	def create_user
		sh %{ #{@bin}mysql -u root -h #{@uri.host} -p --batch --execute "CREATE DATABASE IF NOT EXISTS #{@dbname}; REPLACE INTO mysql.user (Host, User, Password, Select_priv, Insert_priv, Update_priv, Delete_priv, Create_priv, Drop_priv, Reload_priv, References_priv, Index_priv, Alter_priv) VALUES('localhost','#{@login}',PASSWORD('#{@password}'), 'Y','Y','Y','Y','Y','Y','Y','Y','Y','Y'); FLUSH PRIVILEGES; GRANT ALL PRIVILEGES ON #{@dbname}.* TO '#{@login}'@'localhost'; FLUSH PRIVILEGES;" }
	end
end
