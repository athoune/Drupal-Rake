namespace :lighty do
	task :conf do
		generate "template/#{@profile['drupal']['appli']}.conf.rhtml", "etc/#{@profile['drupal']['appli']}.conf"
		generate "template/drupal.lua.rhtml", "etc/drupal.lua"
	end
	task :linuxConf => :conf do
		sh "sudo cp etc/#{@profile['drupal']['appli']}.conf /etc/lighttpd/conf-enabled/"
	end
end
