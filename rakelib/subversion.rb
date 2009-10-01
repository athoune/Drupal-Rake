module Subversion
	def Subversion.autocommit(source, repo)
		if source[-1] == '/'
			source = source[0..-1]
		end
		sources = []
		l_source = source.length + 1
		Dir["#{source}/**/*"].each do |f|
			sources << f[l_source..f.length]
		end
		folder = "/tmp/svnisation"
		if File.exist? folder
			`rm -rf #{folder}`
		end
		`mkdir -p #{folder}`
		svn_checkout repo, folder
		repos = []
		Dir["#{folder}/**/*"].each do |f|
			repos << f[16..f.length]
		end
		puts sources.inspect
		sources.each do |s|
			if File::directory? "#{source}/#{s}"
				mkdir_p "#{folder}/#{s}"
			else
				copy "#{source}/#{s}", "#{folder}/#{s}"
			end
		end
		Dir.chdir folder do
			(repos - sources).each do |d|
				puts "[Info] #{d} va disparaitre"
				sh "svn rm #{d}"
			end
			(sources - repos).each do |d|
				puts "[Info] #{d} va apparaitre"
				sh "svn add #{d}"
			end
			sh 'svn commit -m "mise à jour du module"'
		end
		`rm -rf #{source}`
		mkdir source
		`cp -r #{folder}/* #{source}/`
	end

	def Subversion.checkout(url, target)
		puts "[SVN] Checking out #{target} from #{url}"
		#revision = svn_info url
		#hash = Digest::SHA1.hexdigest url
		#path = "/tmp/svn/tmp/#{hash}/#{revision}"
		#mkdir_p path
		#`svn co #{url} #{path}`
		`svn co #{url} #{target}`
	end

	def Subversion.update(target)
		puts "[SVN] Update de #{target}"
		`cd #{target} && svn update`
	end

	def Subversion.info(url)
		doc = REXML::Document.new `svn info --xml #{url}`
		return doc.elements['info/entry'].attributes['revision']
	end
end