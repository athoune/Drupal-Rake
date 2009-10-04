def noTrailingSpace(path)
	if path[-1] == 47
		path[0, (path.length-1)]
	else
		path
	end
end

def generate(template, destination, binding=binding)
	p "[Generate] #{template} -> #{destination}"
	template = File.read(template)
	res = ERB.new(template).result(binding)
	File.open(destination, 'w') {|f| f.write(res) }
end