require 'yaml'
require 'rubygems'
require 'deep_merge'

module Profile

	def Profile.profile
		name = ENV.fetch('PROFILE', ENV['HOME'].split('/').last).downcase
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
			p "profile: #{cnf}"
		end
		return profile
	end

end
