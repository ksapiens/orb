# ORB - Omnipercipient Resource Browser
# 
# 	Entities
#
# copyright 2016 kilian reitmayr

class Item #< String
	#attr_reader :full#, :delimiter, :parameter, :description
	attr_reader :letters, :type, :area #, :delimiter, :parameter, :description
	def to_s; @letters; end
	#def inspect; to_s; end
	def draw area
		#LOG.debug self.to_s
		@type.draw color:color, area: area
		@letters[0..area.width-2].draw color:color, 
			area:area, selection: true#area.is_a?( List	)
	end
	def width; @letters.length+1; end
	def color 
		classname = self.class
		until COLORS.include? classname.to_s.downcase.to_sym do
			classname = classname.superclass
		end
		classname.to_s.downcase.to_sym
	end
	def initialize letters=""; 
		@type = " "
		@letters = letters
	end
	def primary; end
end
#class Special < Item; end
class Option < Item
	def width; (@letters+@description).length; end
	def initialize outline, description=""
		#/(?<letters>-+\w+)(?<delimiter>[ =])(?<parameter>.*)/.match(option).to_h)
		@letters, @delimiter, @parameter = /(-+[[:alnum:]]+)([ =]?)(.*)$/.match( outline )[1..3]
		@type = "-"
		@description = description
	end
	def draw x=nil, y=nil, area
		#@letters[0..9].ljust(10).draw \
		@letters.draw color:color, area:area, selection: true
		" ".draw area:area
		@description[0..area.width-@letters.length-2].draw color: :description, area:area if area.width > LIMIT #area.is_a? List
	end
	def primary
		#if COMMAND.input.include? self
		#	COMMAND.input -= [self]
		#else
		COMMAND.add self 
		#end
		#[]
	end	
end
class Section < Item
	def initialize letters, content
		@content = content
		super letters
	end
	def primary #restore
		$workspace.pop
		[ @content ]
	end
end
class Entry < Item
	attr_reader :path, :type, :shape
	def initialize path, letters=path.split("/")[-1]
		super letters
		@type = "/"
		#@shape = /(?:[\s=])\/\S*/
		@path = path

	end
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
		if area == COMMAND			
			@history << Command.new( area.content.dup )
			system "%s %s &" % [TERM, area.content.join(" ")]
		else
			
			COMMAND.content = [self]  #@letters 
			man = ManPage.new(@letters)
			if man.page
				[ @history + man.page.map{ |section ,content| 
						Section.new section, content },
			  	man.options.map{ | outline, description |	
						Option.new( outline.split(",").last, description) }
				]
			else
				[ `COLUMNS=1000 #{letters} --help` ]
			end
		end
	end 
end
class Command < Item
	def initialize content
		@content = content
		super @content[1..-1].join
		@type = ">"
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
class Textfile < Entry; end

class Container < Item
	def initialize items, letters
		super letters
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
	def initialize letters=ENV["USER"]
		super letters
		@type = "@"
	end
end
class Host < Item
	def initialize letters="localhost"
		super letters
		@type = ":"
		@shape = //
		#if /\w+\.(?:gg|de|com|org|net)/.match letter
	end
end
class Type < Item
	def initialize klass, letters=klass.to_s.downcase
		super letters
		@type = "?"
		@klass = klass
	end
	def primary
		[ [ Add.new(@klass) ] + 
			$stack.content.select{|item| item.is_a? @klass } ]
	end
end
class Add < Item
	def initialize klass, letters=klass.to_s.downcase
		super letters
		@type = "+"
		@klass = klass
	end
	def primary
		Item.new(@klass.to_s + " : ").draw COMMAND
		#$stack << @klass.new(COMMAND.getstr)
		[]
	end
end


#class Text < Item
class Word < Item
#	def initialize letters
#		@type = " "
#		super letters
#	end
end


	
