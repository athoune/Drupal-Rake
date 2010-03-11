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

DRUSH_VERSION = "All-versions-3.0-beta1"
DRUPAL_INSTALLED = "#{@profile['drupal']['path']}/index.php"
DRUSH_INSTALLED = "bin/drush/#{DRUSH_VERSION}.version"

namespace :drupal do
	namespace :core do
		
		file "#{@profile['drupal']['path']}/sites/default/files" => DRUPAL_INSTALLED do
			# [TODO] use real Drupal default/files
			# [TODO] rights
			sh "sudo mkdir -p #{@profile['drupal']['path']}sites/default/files && sudo chmod 777 #{@profile['drupal']['path']}sites/default/files" 
		end
		
		#naked drupal
		file DRUPAL_INSTALLED do
			url = case @profile['drupal'].fetch('flavor', 'vanilla')
				when 'pressflow' : "http://launchpad.net/pressflow/6.x/#{@profile['drupal']['version']}/+download/pressflow-#{@profile['drupal']['version']}.tar.gz"
				when 'acquia' :    "http://acquia.com/files/downloads/acquia-drupal-#{@profile['drupal']['version']}.tar.gz"
				else               "http://ftp.drupal.org/files/projects/drupal-#{@profile['drupal']['version']}.tar.gz"
				end
			tarball = @fetcher.fetch url
			sh "mkdir -p #{@profile['drupal']['path']}"
			Dir.chdir '/tmp' do
				folder = `tar -tf #{tarball}`.split('/')[0]
				sh "rm -r #{folder}" if File.exist? folder
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
		
		#install or update sites data
		task :sites => DRUPAL_INSTALLED do
			mkdir_p 'devel'
			@profile['drupal']['sites'].each do |key, url|
				Subversion.get url, "#{@profile['drupal']['path']}sites/#{key}"
				if not File.exist? "devel/#{key}"
					sh "ln -s #{@profile['drupal']['path']}sites/#{key} devel/#{key.gsub(/\//, '_')}"
				end
			end
		end
		
		task :init => [:patch, :conf, "#{@profile['drupal']['path']}sites/default/files"] do
			mkdir_p '../sites/all/modules/custom'
			#mkdir_p ''
			if not File.exist? '../sites/.svn'
				Subversion.add '../sites'
				Subversion.commit '../sites', 'initial folders'
				url = Subversion.url '..'
				Subversion.checkout "#{url}/sites/all", "#{@profile['drupal']['path']}sites/all"
				profile = Profile.read("profile.yml")
				if not profile['drupal'].key? 'sites'
					profile['drupal']['sites'] = {}
				end
				profile['drupal']['sites']['all'] = "#{url}/sites/all"
				Profile.write('profile.yml', profile)
				puts "[Info] profile.yml is modified"
			end
		end
		task :install => [:patch, :conf, :sites, "drupal:cron"] do
			@drupal.updatedb
			@drupal.clear_cache
		end
		
		task :upgradeCore do
			backup = "/tmp/drupal-backup/#{Time.now.to_i}/"
			sh "mkdir -p #{backup}"
			sh "cp -r #{@profile['drupal']['path']}sites/* #{backup}"
			sh "sudo rm -r #{@profile['drupal']['path']}"
			Rake::Task["drupal:core:patch"].invoke
			sh "sudo mv #{backup}* #{@profile['drupal']['path']}sites/"
			sh "rm -r #{backup}"
			@drupal.updatedb
		end

		task :conf => @profile['drupal']['path'] do
			mkdir_p "#{@profile['drupal']['path']}sites/default"
			settings = "#{@profile['drupal']['path']}sites/default/settings.php"
			if File.exist?(settings) and not File.writable?(settings)
				sh "sudo chmod +w #{settings}"
			end
			if not File.exist? "template/settings.php.rhtml"
				mkdir_p "template"
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

		task :patch => "#{@profile['drupal']['path']}PATCH"

	end

	file "#{@profile['drupal']['path']}PATCH" => DRUPAL_INSTALLED do
		if File.directory? 'patches'
			Dir.glob('patches/*.patch').each do |patch|
				p patch
				sh "patch --directory=#{@profile['drupal']['path']} -N -p0 -i `pwd`/#{patch}"
			end
			sh "touch #{@profile['drupal']['path']}PATCH"
		end
	end

	namespace :module do
		task :update => [DRUSH_INSTALLED, DRUPAL_INSTALLED] do
			@drupal.update
		end
		desc "download a module or a theme"
		task :dl, [:module]  => DRUSH_INSTALLED do |t,args|
			@drupal.dl args.module
		end
		desc "Commit a module"
		task :commit, [:truc] => DRUSH_INSTALLED do |t, args|
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
			raise StandardError, "#{args.truc} is neither a module, nor a theme"
		end
	end
	
	namespace :drush do
		file DRUSH_INSTALLED => "drupal:conf" do
			drush = @fetcher.fetch "http://ftp.drupal.org/files/projects/drush-#{DRUSH_VERSION}.tar.gz"
			Rake::Task['drupal:drush:clean'].invoke
			mkdir_p 'bin'
			Dir.chdir 'bin' do
				sh "tar -xvzf #{drush}"
			end
			sh "chmod +x bin/drush/drush"
			sh "touch bin/drush/#{DRUSH_VERSION}.version"
		end
		
		task :install => DRUSH_INSTALLED
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
		
		task :_load => DRUSH_INSTALLED do
			@db.load dump
			@drupal.updatedb
			@drupal.clear_cache
		end
		
		desc "create db user"
		task :user do
			@db.create_user 
		end
		
		desc "database setup and first import"
		task :install => [:upgrade]
	end
	
	task :enable  => DRUSH_INSTALLED do
		@profile['drupal'].fetch('modules',[]).each do |m|
			@drupal.enable m
		end
	end
	
	task :variables => DRUSH_INSTALLED do
		if @profile['drupal'].key? 'variables'
			@profile['drupal']['variables'].each do |k,v|
				if v == nil
					@drupal.vdel k
				else
					@drupal.vset k, v
				end
			end
		end
	end
	
	desc "Launch cron task"
	task :cron => DRUSH_INSTALLED do
		@drupal.cron
	end

	desc "Clear cache"
	task :clear => DRUSH_INSTALLED do
		@drupal.clear_cache
	end	
	
	desc "Build Drupal's settings"
	task :conf => 'drupal:core:conf'

	desc "Install Drupal"
	task :install => ['db:install', :update]
	
	desc "Initialize"
	task :init => ['drush:install','db:user', 'core:init'] do
		puts "Open http://#{@profile['web']['host']}:#{@profile['web']['port']}/#{@profile['drupal']['appli']}/install.php"
	end
	
	desc "Get the newest Drupal with the newest snapshot"
	task :lastOne => [:clean, :install, 'db:upgrade']
	
	task :update => ['core:install', :variables]

	desc "Cleanup"
	task :clean => ['core:clean', 'drush:clean']
	
	desc "Upgrade drupal core without breaking customize"
	task :upgrade => 'core:upgradeCore'
	
	file "#{@profile['drupal']['path']}scripts/run-tests.sh" do
		cp "#{@profile['drupal']['path']}sites/all/modules/simpletest/run-tests.sh", "#{@profile['drupal']['path']}scripts/run-tests.sh"
	end
	
	task :test => "#{@profile['drupal']['path']}scripts/run-tests.sh" do
		@drupal.test
	end
end

desc "Update"
task :update => "drupal:update"