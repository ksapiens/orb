
# ORB - Omnipercipient Resource Browser
# 
# 	Entities
#
# copyright 2016 kilian reitmayr

class Item 
#	attr_reader :name, :active, :parent, :silblings, :children, :color, :actions, :default #, :x, :y
	attr_reader :active
	def to_s; @name; end
	def draw x, y, area
		@name.draw color, x, y, area
	end
	def width;	@name.length; end
	def color 
		classname = self.class
		until COLORS.include? classname.to_s.downcase.to_sym do
			classname = classname.superclass
		end
		classname.to_s.downcase.to_sym
	end
	def initialize name; @name = name;	end
	def toggle content, restore=nil
		@active = !@active
		if @active
			@name = "> " + @name
			@restore = restore
			content 
		else
			@name = @name[2..-1]
			{ down: @restore } 
		end
	end
end
class Special < Item; end
class Option < Special
	attr_reader :short, :long, :description
	def primary
		@cmd += long ? long : short
	end	
end
class Section < Special
	def initialize name, content
		@content = content
		super name
	end
	def primary restore
		{ right: @content }
	end
end
class Recent < Special
	def initialize n="recent"
		@name = n; end
end	
class Frequent < Special
	def initialize n= "frequent"
		@name =n;end
end

class Entry < Item
	def initialize path, name=path.split("/")[-1]
		@path = path
		super name;	end
	def primary
		system TERM + " xdg-open %s" % @path; end
end

class Executable < Entry
	def primary restore=nil
		man = ManPage.new(@name)
		sections = man.page.map{ |s,c| 
			Section.new s,c }
			#Section.new s,c.gsub( /^[[:blank:]]+/,"") }
		toggle( { down: sections }, restore )
		  #right: man.page["NAME"]
	end 
end
class Directory < Entry
	def primary restore=nil
		@entries = { right: [], down: [] }
		`file -i #{@path}/*`.each_line do |line|
			next if line[/cannot open/] || line[/no read permission/]
			types = line[/:(.*);/][2..-2].split "/"
    	type = ( (%w{ directory } & types) + ["entry"] ).first
    	path = line[/^.*:/][0..-2]
    	if type != "directory" && FileTest.executable?(path)
  			type = "executable";end

      entry = eval( "%s.new '%s'" % [type.capitalize, path])
    	
    	if type == "directory"
    		@entries[:down] << entry
    	else
    		@entries[:right] << entry
    	end
    end
		toggle( @entries, restore )
	end
end
