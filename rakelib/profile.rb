require 'yaml'
require 'deep_merge'

module Profile

	def Profile.profile
		name = (ENV.key? 'PROFILE') ? ENV['PROFILE'] : ENV['HOME'].split('/').last
		uname = `uname`.strip.downcase
	
		if not File.exist? "profile.yml" or File.zero? "profile.yml"
			raise StandardError, "You have to create a non empty profile.yml"
		end
		profile = YAML::load(IO.read("profile.yml"))

		cnf = "profile.#{name}.#{uname}.yml"
		if ! File.exist?(cnf)
			cnf = "profile.#{name}.yml"
		end
		if File.exist?(cnf)
			profile = profile.deep_merge!(YAML::load(IO.read(cnf)))
		end
		return profile
	end

end