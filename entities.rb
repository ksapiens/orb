# ORB - Omnipercipient Resource Browser
# 
# 	Entities
#
# copyright 2016 kilian reitmayr

require "shellwords"

class Item 
#	attr_reader :name, :active, :parent, :silblings, :children, :color, :actions, :default #, :x, :y
	attr_reader :active
	def to_s; @name; end
	def draw x=nil, y=nil, area#=@area
		((@active ? "> " : "") + to_s)[0..area.width-1].draw	color: color, area: area, selection: true	
	end
	def width; to_s.length + (@active ? 2 : 0); end
	def color 
		classname = self.class
		until COLORS.include? classname.to_s.downcase.to_sym do
			classname = classname.superclass
		end
		classname.to_s.downcase.to_sym
	end
	def initialize name=""; @name = name;	end
	def toggle; @active = !@active; end
end
#class Special < Item; end
class Option < Item
	attr_reader :name, :delimiter, :parameter, :description
	def initialize outline, description
#		if outline.include? ","
			outline = /(-+([[:alnum:]]+)?)([\ =]?)(.*)$/.match	\
				outline.split(",")[-1]
#		else
#			outline = /(-+[[:alnum:]]+)([\ =]?)(.*)$/.match	\
#			outline.split(/(-+[[:alnum:]]+)/ )
#		end
		#LOG.debug outline		
		@delimiter, @parameter = outline[2..3] #if outline.size > 2
		@description = description
		super outline[1]
	end
	def width; (@name+@description).length; end
	def draw x=nil, y=nil, area
		@name[0..9].ljust(10).draw \
			color:color, area:area, selection: true
		@description[0..area.width-11].draw \
			color: :description, area:area 
		#$/.draw({ area:area })
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
class Builder < Item
	def initialize manpage
		super "BUILD"
		@manpage = manpage
	end
	def primary
		{ right: @manpage.options.map{ | outline, description |
				Option.new outline, description }}
	end
end
class Section < Item
	def initialize name, content
		@content = content
		super name
	end
	def primary #restore
		{ right: @content }
	end
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
			sections = man.page.map{ |section ,content| 
					Section.new section, content }
				#Section.new s,c.gsub( /^[[:blank:]]+/,"") }
			#LOG.debug $history
			{ down: ($history[:apps][self] || []) +	
					[ Builder.new(man) ] + sections,
		  	right: man.page["NAME"] }
		else
			COMMAND.primary
			{}
		end
	end 
end
class Directory < Entry
	def primary #restore=nil
		@entries = { right: [], down: [] }
		`file -i #{@path}/*`.each_line do |line|
			next if line[/cannot open/] || line[/no read permission/]
			
			types = /:\s*([\w-]+)\/([\w-]+)/.match(line)[1..2]
    	type = ( (%w{ directory } & types) + ["entry"] ).first
    	path = line[/^.*:/][0..-2]
    	if type != "directory" && FileTest.executable?(path)
  			type = "executable";end

      entry = eval "#{type.capitalize}.new %q[#{Shellwords.escape path}]" 
    	#LOG.debug entry
    	if type == "directory"
    		@entries[:down] << entry
    	else
    		@entries[:right] << entry
    	end
    end
		@entries
	end
end
class Container < Item
	def initialize items, name
		super name
		@items = items
	end
	def primary
		result = { right: [], down: [] }
		for item in @items
		  single = item.primary
			result[:down] += single[:down]
			result[:right] += single[:right]
		end
		result
	end
end
class Prompt < Item
	def initialize
		super ENV["PWD"]+"> "
	end
end
class Command < Item
#include Generic
#include Enumerable
	attr_accessor :input
	def initialize #args
		@input = []
		#parse args
		super ""#args
	end
	def to_s
		@input.map(&:name).join(" ")
	end
	def draw area
		#LOG.debug self#height
		to_s.draw color: color, area: area
	end
	def primary x=nil,y=nil
		LOG.debug "%s %s" % [TERM, to_s]
		$history[:apps][@input.first] ||= []
		$history[:apps][@input.first] << self.dup #@input.dup 
		
		system "%s %s &" % [TERM, to_s]
	end
	
end
