# ORB - Omnipercipient Resource Browser
# 
# 	Items
#
# copyright 2016 kilian reitmayr

class Item #< String
	attr_reader :name, :type#, :shape#
#	attr_reader :type#, :shape#
	attr_accessor :x, :y#, :skip#, :area 
	def to_s; @name; end
	#def image #short=true
		#[ ( @alias ? @alias : @name).colored( color )]
	#	{ name: @name }
	#end
	#def width; image.join.length; end
	#def width; @name.length + 1; end
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
	def initialize name=''; 
		@type ||= ""
		@name ||= name#.colored color
	end
	def has? variable; instance_variables.include? variable; end 
	def primary; content; end
	def content; end
	def add; COMMAND.add self; end
	def action id=KEY_TAB
		#LOG.debug "action #{id}"
		case id
			when KEY_TAB, KEY_MOUSE
				primary #content
			when KEY_CTRL_A
				add
		end
	end
end

class Entry < Item
	attr_reader :path, :description
	def initialize path, name=path.split("/")[-1]
		#@color = :orange
		@type = "/"
		#@shape = /\/\w+[\/\w]+/
		@path = path.colored color
		super name#.gsub /$\//, ''
	end

	#def eql? (object)
	#	path == object.path || !path
	#end
	#def image #path=false#x=nil, y=nil, area
	#	super +
	#	{ path: @path,
	#		description: `whatis #{@name}` }
	#end
			#[(path ? @path : @name ).colored( color )]
	def description
		unless @description #or begin
			if (whatis = `whatis #{@name}`).empty? 
				@description = `ls -dalh #{@path}`
			else
				@description = whatis.lines.first[23..-1] 
			end
		end	
		@description		
	end
end
class Directory < Entry
	def content #restore=nil
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
	def content 
		#super
		COMMAND.content.clear
		COMMAND.add self
		man = ManPage.new(@name)
		if man.page
			[[Collection.new( @history, "history" )] +
				man.options.map{ | outline, description |	
					Option.new( outline.split(",").last, description) } +
				man.page.map{ |section ,content| 
					Section.new section, content } ]
		else [ `COLUMNS=1000 #{name} --help` ];end
	end 
end

class Textfile < Entry
	def content;super;[path.read];end
end	
class Video < Entry; end
class Audio < Entry; end
class Image < Entry; end

class Special < Entry; end
class Symlink < Special; end
class Fifo <  Special; end
class Socketfile < Special; end
class Chardevice < Special; end

class Collection < Item
	attr_reader :items
	def initialize items, name
		@items = items
		#@color = @items.first.color
		@type ||= @items.first.type
		super name
	end
	def content; [@items]; end
end
class Container < Collection
	def content
		result = [] # { right: [], down: [] }
		for item in @items
		  item.content.each_with_index{ |value,index|
				result[index] ||= []
				result[index] += value }
#			$stack.content.shift
		end
		result
	end
end
class Command < Collection
	#attr_accessor :sequence
	def initialize input
		@type = ">"
		case input
			when String 
				parts = input.strip.split(/\s(-{1,2}[^-]*)/)
				return if parts.empty?
				path = `which "#{ Shellwords.escape parts[0].split[0] }" 2> /dev/null`
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
		super @sequence, @sequence.join("")
	end
	#def image #short=false
	#	@sequence.join ""
		#@sequence.map{|part| part.image.first }				
	#end
	def add
		COMMAND.content = @items
	end
	def content#execute
		LOG.debug "com #{self}"
		@items.first.history << self
		[ `#{@items.join ' '}` ]
	end
end

class Option < Item
	attr_reader :description
	def initialize outline, description=""
		@type = "-"
		#/(?<name>-+\w+)(?<delimiter>[ =])(?<parameter>.*)/.match(option).to_h)
		@name, @delimiter, @parameter = /-(-?[[:alnum:]]*)([ =]?)(.*)$/.match( outline )[1..3]
		@type = "-"
		@description = description.colored :description
		super @name
	end
	def image #long=false#x=nil, y=nil, area
		#@name[0..9].ljust(10).draw \
		super +	{ description: " " + @description }
		#(long ?  [" " + @description] : [] )
	end
	def primary; add;	end
	#def add#content
	#	COMMAND.add self 
	#	nil #[]
	#end	
end

class User < Item
	def initialize name=ENV["USER"]
		super name
		@type = "@"
	end
	#def content;	end
end
class Host < Item
	def initialize name="localhost"
		super name
		@type = ":"
		#@shape = //
		#if /\w+\.(?:gg|de|com|org|net)/.match letter
	end
	#def content	end
end
class Type < Item
	def initialize klass, name=klass.to_s.downcase
		super name
		@type = "?"
		@klass = klass
	end
	def content
		[ [ Add.new(@klass) ] + 
			$stack.content.select{|item| item.is_a? @klass } ]
	end
end
class Add < Item
	def initialize type, name=type.to_s.downcase
		super name
		@type = "+"
		#@name = name
	end
	#def content
	def primary 
		COMMAND.content = [ Text.new(@name.to_s + " : ") ]
		item = @klass.new(COMMAND.getstr)
		$stack << item
		item.content
		#[]
	end
end

class Section < Item
	def initialize name, content
		@type = " "
		@content = content
		super name
	end
	def content #restore
		#$world.pop
		[ @content ]
	end
end
class Text < Item
#	type = ""
end
class Word < Item

	def initialize name
		super name
		@type = " "
	end
end


	
