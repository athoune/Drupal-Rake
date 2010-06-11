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
				sh "svn co http://svn.php.net/repository/php/php-src/branches/PHP_5_3/sapi/fpm sapi/fpm"
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
		task :rcd => :patch do
			sh "sudo cp /tmp/php-#{PHP_VERSION}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm"
			sh "sudo update-rc.d php-fpm defaults"
		end
		task :install => "/tmp/php-#{PHP_VERSION}/#{PHP_VERSION}-#{FPM_VERSION}.install"
		task :apc => :install do
			@php.pecl_install 'APC-3.1.3p1', 'no'
		end
		task :uploadprogress => :install do
			@php.pecl_install 'uploadprogress'
		end
		task :memcache => :install do
			@php.pecl_install 'memcache', 'yes'
		end
		task :extensions => [:apc, :uploadprogress, :memcache]

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

	file 'template/php-fpm.conf.rhtml' do
		cp 'rakelib/default/php-fpm.conf.rhtml', 'template/php-fpm.conf.rhtml'
	end

	task :conf => ['template/php-fpm.conf.rhtml'] do
		generate 'template/php-fpm.conf.rhtml', 'etc/php-fpm.conf'
	end
	task :linuxConf => [:conf, 'php:fpm:rcd'] do
		sh "sudo cp etc/php-fpm.conf /opt/php-fpm/etc/php-fpm.conf"
	end
end
