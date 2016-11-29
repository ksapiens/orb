
# ORB - Omnipercipient Resource Browser
# 
# 	Entities
#
# copyright 2016 kilian reitmayr

class Item 
#	attr_reader :name, :active, :parent, :silblings, :children, :color, :actions, :default #, :x, :y
	attr_reader :active
	def to_s; @name; end
	def draw x=nil, y=nil, area#=@area
		((@active ? "> " : "") + @name)[0..area.width-1].draw color, x, y, area
		$/.draw area unless x && y || area.width <= width
	end
	def width; @name.length + (@active ? 2 : 0); end
	def color 
		classname = self.class
		until COLORS.include? classname.to_s.downcase.to_sym do
			classname = classname.superclass
		end
		classname.to_s.downcase.to_sym
	end
	def initialize name; @name = name;	end
	def toggle; @active = !@active; end
end
class Special < Item; end
class Option < Special
	attr_reader :name, :delimiter, :parameter, :description
	def initialize outline, description

#		if outline.include? ","
			outline = /(-+([[:alnum:]]+)?)([\ =]?)(.*)$/.match	\
				outline.split(",")[-1]
#		else
#			outline = /(-+[[:alnum:]]+)([\ =]?)(.*)$/.match	\
#			outline.split(/(-+[[:alnum:]]+)/ )
#		end
		LOG.debug outline		
		@delimiter, @parameter = outline[2..3] #if outline.size > 2
		@description = description
		super outline[1]
	end
	def width; (@name+@description).length; end
	def draw x=nil, y=nil, area
		("%-9s" % @name[0..9]).draw color, x, y, area
		@description[0..area.width-11].draw :description, x, y, area
		$/.draw area
	end
	def primary
		if COMMAND.input.include? self
			COMMAND.input -= [self]
		else
			COMMAND.input << self 
		end
		{}
	end	
end
class Builder < Special
	def initialize manpage
		super "BUILD"
		@manpage = manpage
	end
	def primary
		{ right: @manpage.options.map{ | outline, description |
				Option.new outline, description }}
	end
end
class Section < Special
	def initialize name, content
		@content = content
		super name
	end
	def primary #restore
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
	attr_reader :name
	def primary #restore=nil
		COMMAND.input = [ self ] #@name 
		man = ManPage.new(@name)
		if man.page
			sections = [ Builder.new(man) ] +
				man.page.map{ |section ,content| 
					Section.new section, content }
				#Section.new s,c.gsub( /^[[:blank:]]+/,"") }
	
			{ down: sections,
		  	right: man.page["NAME"] }
		else
			COMMAND.primary
		end
	end 
end
class Directory < Entry
	def primary #restore=nil
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
		@entries
	end
end
