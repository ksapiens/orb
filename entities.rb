# ORB - Omnipercipient Resource Browser
# 
# 	Items
#
# copyright 2016 kilian reitmayr

class Item #< String
	attr_reader :alias, :letters, :type, :shape#
	attr_accessor :x, :y#, :skip#, :area 
	#def to_s; @letters; end
	
	def image short=true
		[ ( @alias ? @alias : @letters).colored( color )]
	end
	def width; image.join.length; end
	#def width; @letters.length + 1; end
#	def self.type name; @type = name; end
#	def self.color name;	@color = name; end
#	def self.shape name;	@shape = name; end
	def color name=self.class
		until color = COLORS.select{|k,v| 
			v[1..-1].include? name }.keys.first 
			name = name.superclass 
		end
		color
	end			
	def initialize letters=''; 
		@type ||= ""
		@letters ||= letters
	end
	def primary; end
	def action id=KEY_TAB
		LOG.debug "action #{id}"
		case id
			when KEY_TAB, KEY_MOUSE
				primary
			when KEY_CTRL_A
				add
		end
	end
end

class Entry < Item
	attr_reader :path
	def initialize path, letters=path.split("/")[-1]
		@color = :orange
		@type = "/"
		@shape = /\/\w+[\/\w]+/
		@path = path
		super letters#.gsub /$\//, ''
	end
	def add#primary
		COMMAND.add self
	end
	#def eql? (object)
	#	path == object.path || !path
	#end
	def image path=false#x=nil, y=nil, area
		[(path ? @path : @letters ).colored( color )]
	end
end
class Directory < Entry
	
	#def initialize path
	#	super path
		#@color = :yellow
	#end
	def primary #restore=nil
		super
		files,directories = [],[] #@entries = { right: [], down: [] }
		`file -i #{@path}/*`.each_line do |line|
			#LOG.debug "dir :#{line}"
			entry = line.entry
    	(entry.is_a?(Directory) ? directories : files ) << 
    		entry if entry
    end
		[directories, files]
	end

end

class Executable < Entry
	attr_accessor :history
	def initialize path
		super path
		@history = []
	end
	def primary 
		super
		COMMAND.content = []
		COMMAND.add self
		man = ManPage.new(@letters)
		if man.page
			[ @history +
				man.options.map{ | outline, description |	
					Option.new( outline.split(",").last, description) } +
				man.page.map{ |section ,content| 
					Section.new section, content } ]
		else [ `COLUMNS=1000 #{letters} --help` ];end
	end 
end
class Special < Entry
	def initialize path
		super path
		@color = :magenta
	end
end
class Symlink < Special; end
class Fifo <  Special; end
class Socketfile < Special; end
class Chardevice < Special; end
class Textfile < Entry
	def initialize path
		super path
		@color = :bright
	end
	def primary;super;[path.read];end
end	
class Video < Entry; @color = :cyan; end
class Audio < Entry; @color = :blue; end
class Image < Entry; @color = :green; end

class Container < Item
	
	def initialize items, letters
		@items = items
		@color = @items.first.color
		@type = @items.first.type
		super letters
	end

	def primary
		result = [] # { right: [], down: [] }
		for item in @items
		  item.primary.each_with_index{ |value,index|
				result[index] ||= []
				result[index] += value }
#			$stack.content.shift
		end
		result
	end
end
#class Special < Item; end
class Option < Item
	def initialize outline, description=""
		@type = "-"
		#/(?<letters>-+\w+)(?<delimiter>[ =])(?<parameter>.*)/.match(option).to_h)
		@letters, @delimiter, @parameter = /-(-?[[:alnum:]]*)([ =]?)(.*)$/.match( outline )[1..3]
		@type = "-"
		@description = description.colored :description
		super @letters
	end
	def image long=false#x=nil, y=nil, area
		#@letters[0..9].ljust(10).draw \
		super +	(long ?  [" " + @description] : [] )
	end
	def primary
		COMMAND.add self 
		nil #[]
	end	
end
class Command < Item
	attr_accessor :sequence
	def initialize input
		@type = ">"
		case input
			when String 
				parts = input.strip.split(/\s(-{1,2}[^-]*)/)
				return if parts.empty?
				#path = `#{shell} -c "which #{parts[0].split[0]} 2> /dev/null"`
				path = `which "#{Shellwords.escape parts[0].split[0]}" 2> /dev/null`
				return if path.empty?
				@sequence ||= [] 
				executable = Executable.new(path.strip)				 
				executable.history << self
				@sequence << executable
				#command = command[/aliased to (.*)$/]
				options = parts[1..-1].reject(&:empty?)
				@sequence << options.map{|part| 
					Option.new part} unless options.empty?
			when Enumerable
				@sequence = input
		end
		super @sequence.join ""
	end
	def image short=false
		@sequence.map{|part| part.image.first }				
	end
	def add
		COMMAND.content = @sequence
	end
	def primary#execute
		#LOG.debug "com #{self}"
		@sequence.first.history << self
		[ `#{@sequence.join ' '}` ]
	end
end

class User < Item

	def initialize letters=ENV["USER"]
		super letters
		@type = "@"
	end
	def primary;	end
end
class Host < Item
	def initialize letters="localhost"
		super letters
		@type = ":"
		#@shape = //
		#if /\w+\.(?:gg|de|com|org|net)/.match letter
	end
	def primary
		
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
	def initialize name, letters=name.to_s.downcase
		super letters
		@type = "+"
		@name = name
	end
	def primary
		COMMAND.content = [ Text.new(@name.to_s + " : ") ]#.image #COMMAND
		#$stack << @klass.new(COMMAND.getstr)
		[]
	end
end

class Section < Item
	def initialize letters, content
		@type = " "
		@content = content
		super letters
	end
	def primary #restore
		#$world.pop
		[ @content ]
	end
end
class Text < Item
#	type = ""
end
class Word < Item

	def initialize letters
		super letters
		@type = " "
	end
end


	
