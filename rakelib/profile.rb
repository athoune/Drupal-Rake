require 'yaml'

module Profile

	def Profile.profile
		name = (ENV.key? 'PROFILE') ? ENV['PROFILE'] : ENV['HOME'].split('/').last
		uname = `uname`.strip.downcase
	
		cnf = "profile.#{name}.#{uname}.yml"
		if ! File.exist?(cnf)
			cnf = "profile.#{name}.yml"
		end
		if ! File.exist?(cnf)
			raise StandardError, "You have to create #{cnf}"
		end
		if File.exist? "profile.yml" and not File.zero? "profile.yml"
			profile = YAML::load(IO.read("profile.yml"))
		end
		if profile == nil
			profile = (YAML::load(IO.read(cnf)))
		else
			profile = profile.merge(YAML::load(IO.read(cnf)))
		end
	end

end