# ORB - Omnipercipient Resource Browser
# 
# 	Entities
#
# copyright 2016 kilian reitmayr

class Item #< String
	#attr_reader :full#, :delimiter, :parameter, :description
	attr_reader :name, :type #, :delimiter, :parameter, :description
	def to_s; @name; end
	#def inspect; to_s; end
	def draw area
		LOG.debug self
		@name[0..area.width-1].draw	color: color, 
			area: area, selection: area.is_a?( List	)
	end
	def width; @name.length; end
	def color 
		classname = self.class
		until COLORS.include? classname.to_s.downcase.to_sym do
			classname = classname.superclass
		end
		classname.to_s.downcase.to_sym
	end
	def initialize name=""; 
		@type = " "
		@name = name;	end
	def primary; end
end
#class Special < Item; end
class Option < Item
	def initialize outline, description=""
		#/(?<name>-+\w+)(?<delimiter>[ =])(?<parameter>.*)/.match(option).to_h)
		@name, @delimiter, @parameter = /(-+[[:alnum:]]+)([ =]?)(.*)$/.match( outline )[1..3]
		@type = "-"
		@description = description
end
	def width; (@name+@description).length; end
	def draw x=nil, y=nil, area
		#@name[0..9].ljust(10).draw \
		@name.draw color:color, area:area, selection: true
		" ".draw area:area
		@description[0..area.width-@name.length-2].draw color: :description, area:area if area.is_a? List
	end
	def primary
		#if COMMAND.input.include? self
		#	COMMAND.input -= [self]
		#else
			COMMAND << self 
		#end
		[]
	end	
end
class Section < Item
	def initialize name, content
		@content = content
		super name
	end
	def primary #restore
		$workspace.pop
		[ @content ]
	end
end
class Entry < Item
	attr_reader :path, :type
	def initialize path, name=path.split("/")[-1]
		@type = "/"
		@path = path
		super name;	end
	#def primary
		#system TERM + " xdg-open %s" % @path; 
	#end
	#def eql? (object)
	#	path == object.path || !path
	#end
end

class Executable < Entry
	attr_accessor :history
	def initialize path
		@history = []
		super path
	end
	def primary area=nil
		if area.is_a? Line			
			@history << Command.new( area.content.dup )
			system "%s %s &" % [TERM, area.content.join(" ")]
		else
			
			COMMAND.content = [self]  #@name 
			man = ManPage.new(@name)
			if man.page
				[ @history + man.page.map{ |section ,content| 
						Section.new section, content },
			  	man.options.map{ | outline, description |	
						Option.new( outline.split(",").last, description) }
				]
			else
				[ `COLUMNS=1000 #{name} --help` ]; end
		end
	end 
end
class Command < Item
	def initialize content
		@type = ">"
		@content = content
		super @content[1..-1].join
	end

	def primary
		COMMAND.content = @content
	end
end
class Directory < Entry
	def primary #restore=nil
		files,directories = [],[] #@entries = { right: [], down: [] }
		`file -i #{@path}/*`.each_line do |line|
			entry = line.entry
    	#LOG.debug entry
    	if entry.is_a? Directory
    		directories << entry 
    	else
    		files << entry
    	end
    end
		[directories, files]
	end
end
class Symlink < Entry; end
class Fifo < Entry; end
class Socket < Entry; end
class Chardevice < Entry; end
class TextFile < Entry; end

class Container < Item
	def initialize items, name
		super name
		@items = items
	end
	def primary
		result = [] # { right: [], down: [] }
		for item in @items
		  item.primary.each_with_index{ |value,index|
				result[index] ||= []
				result[index] += value }
		end
		result
	end
end
class User < Item
	def initialize name=ENV["USER"]
		@type = "@"
		super name
	end
end
class Host < Item
	def initialize name="localhost"
		@type = ":"
		super name
	end
end
class Type < Item
	def initialize klass, name=klass.to_s.downcase
		@type = "?"
		@klass = klass
		super name
	end
	def primary
		[ [ Add.new(@klass) ] + 
			$stack.content.select{|item| item.is_a? @klass } ]
	end
end
class Add < Item
	def initialize klass, name="add "+klass.to_s.downcase
		@type = "+"
		@klass = klass
		super name
	end
	def primary
		Item.new(@klass.to_s + " : ").draw COMMAND
		#$stack << @klass.new(COMMAND.getstr)
		[]
	end
end


#class Text < Item
class Word < Item
	def initialize name
		@type = " "
		super name
	end
end


	
