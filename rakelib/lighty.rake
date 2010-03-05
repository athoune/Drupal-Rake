namespace :lighty do
	task :conf do
		generate "template/communication.conf.rhtml", "etc/communication.conf"
		generate "template/drupal.lua.rhtml", "etc/drupal.lua"
	end
	task :linuxConf => :conf do
		sh "sudo cp etc/communication.conf /etc/lighttpd/conf-enabled/"
	end
end
