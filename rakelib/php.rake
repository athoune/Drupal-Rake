namespace :php do
	PHP_VERSION = '5.3.2'
	namespace :fpm do
		file "/tmp/php-#{PHP_VERSION}.tar.bz2" do
			sh "cd /tmp && curl -O http://be.php.net/distributions/php-#{PHP_VERSION}.tar.bz2"
		end
		file "/tmp/php-#{PHP_VERSION}" do
			Rake::Task["/tmp/php-#{PHP_VERSION}.tar.bz2"].invoke
			sh "cd /tmp && tar -xvjf php-#{PHP_VERSION}.tar.bz2"
		end
		task :src => "/tmp/php-#{PHP_VERSION}"
		file "/tmp/php-#{PHP_VERSION}/FPM_PATCH" do
			Rake::Task["/tmp/php-#{PHP_VERSION}"].invoke
			Dir.chdir "/tmp/php-#{PHP_VERSION}" do
				sh "svn co http://svn.php.net/repository/php/php-src/trunk/sapi/fpm sapi/fpm"
				sh "touch FPM_PATCH"
				sh "./buildconf --force"
			end
		end
		task :patch => "/tmp/php-#{PHP_VERSION}/FPM_PATCH"
		
		namespace :libevent do
			LIBEVENT_VERSION = '1.4.13-stable'
			file "/tmp/libevent-#{LIBEVENT_VERSION}.tar.gz" do
				sh "cd /tmp && curl -O http://www.monkey.org/~provos/libevent-#{LIBEVENT_VERSION}.tar.gz"
			end
			file "/tmp/libevent-#{LIBEVENT_VERSION}" do
				Rake::Task["/tmp/libevent-#{LIBEVENT_VERSION}.tar.gz"].invoke
				sh "cd /tmp/ && tar -xvzf libevent-#{LIBEVENT_VERSION}.tar.gz"
			end
			task :src => "/tmp/libevent-#{LIBEVENT_VERSION}"
			task :install => :src do
				Dir.chdir "/tmp/libevent-#{LIBEVENT_VERSION}" do
					sh "./configure --prefix=/opt/libevent"
					sh "make"
					sh "sudo make install"
				end
				
			end
		end
	end
end
