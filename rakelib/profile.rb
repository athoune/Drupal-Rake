require 'yaml'
require 'ftools'
require 'rubygems'
require 'deep_merge'

module Profile

	def Profile.profile
		name = ENV.fetch('PROFILE', ENV['HOME'].split('/').last).downcase
		uname = `uname`.strip.downcase
	
		if not File.exist? "profile.yml" or File.zero? "profile.yml"
			File::copy 'rakelib/default/profile.yml', '.'
			raise StandardError, "A dummy profile was just created, modify it now"
		end
		profile = YAML::load(IO.read("profile.yml"))

		cnf = "profile.#{name}.#{uname}.yml"
		if ! File.exist?(cnf)
			cnf = "profile.#{name}.yml"
			File.new(cnf, 'w').close if ! File.exist?(cnf)
		end
		if File.exist?(cnf)
			profile = profile.deep_merge!(YAML::load(IO.read(cnf)))
			puts "[Info] using profile: #{cnf}"
		end
		return profile
	end
	
	def Profile.read(path)
		return YAML::load(IO.read(path))
	end
	
	def Profile.write(path, data)
		f = File.open(path, 'w')
		f.write(data.to_yaml)
		f.close
	end

end
