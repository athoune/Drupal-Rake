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
		mysql = %{ #{@bin}mysql -u #{@login} --password='#{@password}' -h #{@uri.host} --batch --execute }
		%w{sessions watchdog cache}.each do |table|
			#sh %{ #{mysql} "TRUNCATE #{@dbname}.#{table}"; true}
		end
		sh "#{@bin}mysqldump -u #{@login} -h #{@uri.host} --lock-tables  --add-locks --ignore-table=#{@dbname}.cache --ignore-table=#{@dbname}.sessions --ignore-table=#{@dbname}.watchdog --password='#{@password}' --quick --default-character-set=utf8  --extended-insert --add-drop-table  #{@dbname} --result-file=dump/#{name}.sql"
		sh "bzip2 dump/#{name}.sql"
	end
	
	def load(name)
		if not File.exist? "dump/#{name}.sql.bz2"
			raise StandardError, "This dump doesn't exist : dump/#{name}.sql.bz2"
		end
		sh "bunzip2 --keep --force dump/#{name}.sql.bz2"
		sh %{ #{@bin}mysql -h #{@uri.host} -u #{@login} --password='#{@password}' #{@dbname} --batch --execute="SOURCE #{`pwd`.strip}/dump/#{name}.sql" }
		sh "rm dump/#{name}.sql"
		#sh "bzcat dump/#{name}.sql.bz2 | #{@bin}mysql -h #{@uri.host} -u #{@login} --password='#{@password}' #{@dbname}"
	end
	
	def create_user
		sh %{ #{@bin}mysql -u root -h #{@uri.host} -p --batch --execute "CREATE DATABASE IF NOT EXISTS #{@dbname}; REPLACE INTO mysql.user (Host, User, Password, Select_priv, Insert_priv, Update_priv, Delete_priv, Create_priv, Drop_priv, Reload_priv, References_priv, Index_priv, Alter_priv) VALUES('localhost','#{@login}',PASSWORD('#{@password}'), 'Y','Y','Y','Y','Y','Y','Y','Y','Y','Y'); FLUSH PRIVILEGES; GRANT ALL PRIVILEGES ON #{@dbname}.* TO '#{@login}'@'localhost'; FLUSH PRIVILEGES;" }
	end
end
