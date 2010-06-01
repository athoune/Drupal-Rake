namespace :php do
	PHP_VERSION = '5.3.2'
	FPM_VERSION = 'SVN'
	require 'rakelib/php.rb'
	@php ||= Php.new @profile['server']
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
		file "/tmp/php-#{PHP_VERSION}/#{PHP_VERSION}-#{FPM_VERSION}.install" do	
			Rake::Task['php:fpm:patch'].invoke
			Rake::Task['php:fpm:libevent:install'].invoke
			Dir.chdir "/tmp/php-#{PHP_VERSION}" do
				sh "./configure --enable-fpm --with-libevent=/opt/libevent --prefix=/opt/php-fpm --with-curl --enable-mbstring --enable-sockets -enable-zip --with-pcre-regex --with-mysqli --with-gd --with-mcrypt --with-fpm-group=nogroup --with-gettext --enable-mbstring --enable-zlib --with-zlib --enable-gd-native-ttf --with-jpeg-dir=/usr/lib/"
				sh "make"
				sh "sudo make install"
				sh "touch #{PHP_VERSION}-#{FPM_VERSION}.install"
			end
		end
		task :install => "/tmp/php-#{PHP_VERSION}/#{PHP_VERSION}-#{FPM_VERSION}.install"
		task :apc => :install do
			if not @php.pecl? 'APC'
				sh "echo 'no' | sudo /opt/php-fpm/bin/pecl install apc-3.1.3p1"
			end
		end
		task :uploadprogress => :install do
			sh "sudo /opt/php-fpm/bin/pecl install uploadprogress"
		end
		task :memcache => :install do
			sh %{echo "yes" | sudo /opt/php-fpm/bin/pecl install memcache}
		end
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
