require 'rakelib/drupal'
require 'rakelib/db'
require 'rakelib/php'
require 'rakelib/tools'
require 'rakelib/subversion'
require 'rakelib/profile'

@profile ||= Profile.profile
@drupal ||= Drupal.new @profile['server'], @profile['drupal']['path']
if @profile.key? 'server'
	server = @profile['server']
else
	server = (`uname`.strip == 'Linux') ? 'linux' : 'mamp'
end
@db ||= Db.new server, @profile['drupal']['db']

namespace :drupal do
	namespace :core do
		file "#{@profile['drupal']['path']}sites/default/files" => @profile['drupal']['path'] do
			# [TODO] use real Drupal default/files
			# [TODO] rights
			sh "sudo mkdir -p #{@profile['drupal']['path']}sites/default/files && sudo chmod 777 #{@profile['drupal']['path']}sites/default/files" 
		end
		
		file @profile['drupal']['path'] do
			url = case @profile['drupal'].fetch('flavor', 'vanilla')
				when 'pressflow' : "http://launchpad.net/pressflow/6.x/#{@profile['drupal']['version']}/+download/pressflow-#{@profile['drupal']['version']}.tar.gz"
				when 'acquia' :    "http://acquia.com/files/downloads/acquia-drupal-#{@profile['drupal']['version']}.tar.gz"
				else               "http://ftp.drupal.org/files/projects/drupal-#{@profile['drupal']['version']}.tar.gz"
				end
			tarball = @fetcher.fetch url
			sh "mkdir -p #{@profile['drupal']['path']}"
			Dir.chdir '/tmp' do
				folder = `tar -tf #{tarball}`.split('/')[0]
				sh "tar -xvzf #{tarball}"
				sh "mv /tmp/#{folder}/* #{noTrailingSpace(@profile['drupal']['path'])}"
				sh "mv /tmp/#{folder}/.htaccess #{noTrailingSpace(@profile['drupal']['path'])}"
				sh "rm -r #{folder}"
			end
			sh "rm -r #{@profile['drupal']['path']}sites/*"
		end
		
		task :clean do
			if File.directory? @profile['drupal']['path']
				#sh "sudo chown -R #{ENV['USER']}  #{@profile['drupal']['path']}"
				sh "sudo rm -r #{@profile['drupal']['path']}"
			end
		end
		
		task :sites => @profile['drupal']['path'] do
			sh "mkdir -p devel"
			@profile['drupal']['sites'].each do |key, url|
				Subversion.get url, "#{@profile['drupal']['path']}sites/#{key}"
				if not File.exist? "devel/#{key}"
					sh "ln -s #{@profile['drupal']['path']}sites/#{key} devel/#{key.gsub(/\//, '_')}"
				end
			end
		end
		
		task :init => [:patch, :conf, "#{@profile['drupal']['path']}sites/default/files"] do
			directory '../sites/all'
			Subversion.add '../sites/all'
		end
		task :install => [:init, :sites]
		
		task :upgradeCore do
			backup = "/tmp/drupal-backup/#{Time.now.to_i}/"
			sh "mkdir -p #{backup}"
			sh "cp -r #{@profile['drupal']['path']}sites/* #{backup}"
			rm_r @profile['drupal']['path']
			Rake::Task["drupal:core:patch"].invoke
			sh "mv #{backup}* #{@profile['drupal']['path']}sites/"
			sh "rm -r #{backup}"
			@drupal.updatedb
		end

		task :conf => @profile['drupal']['path'] do
			sh "mkdir -p #{@profile['drupal']['path']}sites/default"
			settings = "#{@profile['drupal']['path']}sites/default/settings.php"
			if File.exist?(settings) and not File.writable?(settings)
				sh "sudo chmod +w #{settings}"
			end
			if not File.exist? "template/settings.php.rhtml"
				sh "mkdir -p template"
				File.open("template/settings.php.rhtml", 'w') do |f|
					f.write %{<?php
$db_url = '<%= @profile['drupal']['db']%>';
$db_prefix = '';
$update_free_access = FALSE;
}
				end
			end
			generate "template/settings.php.rhtml", "#{@profile['drupal']['path']}sites/default/settings.php"
		end
	end

	file "#{@profile['drupal']['path']}PATCH" => @profile['drupal']['path'] do
		if File.directory? 'patches'
			Dir.glob('patches/*.patch').each do |patch|
				p patch
				sh "patch --directory=#{@profile['drupal']['path']} -N -p0 -i `pwd`/#{patch}"
			end
			sh "touch #{@profile['drupal']['path']}PATCH"
		end
	end

	task :patch => "#{@profile['drupal']['path']}PATCH"

	namespace :module do
		task :update => 'bin/drush' do
			@drupal.update
		end
		desc "download a module or a theme"
		task :dl , [:module] do |t,args|
			@drupal.dl args.module
		end
		desc "Commit un module passé en argument"
		task :commit, [:truc] do |t, args|
			puts "#{@profile['drupal']['path']}sites/all/modules/#{args.truc}"
			if File.exist? "#{@profile['drupal']['path']}sites/all/modules/#{args.truc}"
				Subversion.autocommit "#{@profile['drupal']['path']}sites/all/modules/#{args.truc}", "#{@profile['drupal']['sites']['all']}/modules/#{args.truc}"
				exit
			end
=begin
			if File.exist? "#{@drupal_webdir}/sites/all/themes/#{args.truc}"
				Subversion.autocommit "#{@drupal_webdir}/sites/all/themes/#{args.truc}", "#{p['svn_ohm']}/sites/trunk/all/themes/#{args.truc}"
				exit
			end
=end
			raise StandardError, "#{args.truc} n'est ni un module, ni un theme"
		end
	end
	
	namespace :drush do
		DRUSH_VERSION = "All-versions-3.0-beta1"
		file "bin/drush/#{DRUSH_VERSION}.version" do
			drush = @fetcher.fetch "http://ftp.drupal.org/files/projects/drush-#{DRUSH_VERSION}.tar.gz"
			Rake::Task['drupal:drush:clean'].invoke
			sh "mkdir -p bin"
			Dir.chdir 'bin' do
				sh "tar -xvzf #{drush}"
			end
			sh "chmod +x bin/drush/drush"
			sh "touch bin/drush/#{DRUSH_VERSION}.version"
		end
		
		task :install => "bin/drush/#{DRUSH_VERSION}.version"
		task :clean do
			if File.exist? 'bin/drush'
				rm_r 'bin/drush'
			end
		end
	end
	
	namespace :db do
		dump = @profile.fetch('dump', 'dump')

		desc "Make a db snapshot"
		task :dump do
			#@drupal.drush 'cache clear'
			@db.dump dump
		end
		
		task :_upgrade do
			Subversion.update "dump/#{dump}.sql.bz2"
		end
		
		desc "Load the last versionned snapshot"
		task :upgrade => [:_upgrade, :load]
		
		desc "Load the last local snapshot"
		task :load => [:_load, "^enable"]
		
		task :_load do
			@db.load dump
			@drupal.updatedb
			@drupal.clear_cache
		end
		
		task :user do
			@db.create_user 
		end
		
		desc "database setup and first import"
		task :install => [:upgrade]
	end
	
	task :enable do
		@profile['drupal'].fetch('modules',[]).each do |m|
			@drupal.enable m
		end
	end
	
	desc "Launch cron task"
	task :cron do
		@drupal.cron
	end

	desc "Clear cache"
	task :clear do
		@drupal.clear_cache
	end	
	
	desc "Build Drupal's settings"
	task :conf => 'core:conf'

	desc "Install Drupal"
	task :install => ['drush:install', 'db:install', 'core:install']
	
	desc "Initialize"
	task :init => ['drush:install','db:user', 'core:init'] do
		p "Open http://#{@profile['web']['host']}:#{@profile['web']['port']}/#{@profile['drupal']['appli']}/install.php"
	end
	
	desc "Get the newest Drupal with the newest snapshot"
	task :lastOne => [:clean, :install, 'db:upgrade']
	
	task :update => ["drush:install", 'core:install']

	desc "Cleanup"
	task :clean => ['core:clean', 'drush:clean']
	
	desc "Upgrade drupal core without breaking customize"
	task :upgrade => 'core:upgrade'
	
	file "#{@profile['drupal']['path']}scripts/run-tests.sh" do
		cp "#{@profile['drupal']['path']}sites/all/modules/simpletest/run-tests.sh", "#{@profile['drupal']['path']}scripts/run-tests.sh"
	end
	
	task :test => "#{@profile['drupal']['path']}scripts/run-tests.sh" do
		@drupal.test
	end
end
