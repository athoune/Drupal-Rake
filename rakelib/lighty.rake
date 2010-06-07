namespace :lighty do
	file 'template/drupal.lua.rhtml' do
		cp 'rakelib/default/drupal.lua.rhtml', 'template/drupal.lua.rhtml'
	end
	file 'template/website.conf.rhtml' do
		cp 'rakelib/default/website.conf.rhtml', 'template/website.conf.rhtml'
	end
	directory 'etc'
	task :conf => ['template/drupal.lua.rhtml', 'template/website.conf.rhtml', 'etc'] do
		generate "template/website.conf.rhtml", "etc/#{@profile['name']}.conf"
		generate "template/drupal.lua.rhtml", "etc/drupal-#{@profile['name']}.lua"
	end
	task :linuxConf => :conf do
		sh "sudo cp etc/#{@profile['name']}.conf /etc/lighttpd/conf-enabled/"
		sh "sudo cp etc/drupal-#{@profile['name']}.lua /etc/lighttpd/conf-enabled/"
	end
end

task :conf => 'lighty:conf'