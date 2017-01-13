# ORB - Omnipercipient Resource Browser
# 
# 	Items
#
# copyright 2016 kilian reitmayr

class Item #< String
	class << self
		attr_accessor :default
	end
	def self.descendants
  	ObjectSpace.each_object(Class).select{ |klass| klass < self }
  end

	attr_reader :name
	attr_accessor :x, :y, :alias
	def to_s; @alias ? @alias : @name; end
	#def to_s; @name; end
	def length; to_s.length; end
	def type name=self.class
		until type = TYPE[name.to_s.downcase.to_sym]
			name = name.superclass 
		end;type
	end			 
	def color name=self.class
		until color = COLOR.select{|k,v| 
			v[1..-1].include? name }.keys.first 
			name = name.superclass 
		end;color
	end			
	def initialize name='', _alias=nil 
		@name ||= name#.colored color
		@alias ||= _alias
	end
	def has? variable; instance_variables.include? variable; end 
	def description;""; end
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
	def primary; open; nil; end
	def open		
		return unless default = self.class.default
		default.add
		self.add
	end
			
	def initialize path, _alias=nil#path#.split("/")[-1]
		_alias = path.split("/")[-1] if _alias == :short
		super path.path, _alias#.gsub /$\//, ''
	end

	def description
		@description or begin
			if (whatis = `whatis #{@name} 2>/dev/null`).empty? 
				#@description = @name.[0..-1*@alias.size] + `ls -dalh #{@name} 2>/dev/null`
				@description = @name +" - "+`ls -dalh #{@name} 2>/dev/null`
			else
				@description = whatis.lines.first[23..-1] 
			end
		end	
	end
end
class Directory < Entry
	def primary; content; end
	def content #restore=nil
		#super
		files,directories = [],[] #@entries = { right: [], down: [] }
		`file -i #{@name}/*`.each_line do |line|
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
	def primary; content; end
	def initialize path, _alias
		super path, _alias
		@history = []
	end
	def content 
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
	def content;super;[@name.read];end
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
		#@type = ">"
		case input
			when String 
				parts = input.strip.split(/\s(-{1,2}[^-]*)/)
				return if parts.empty?
				path = `which "#{ Shellwords.escape parts[0].split[0] }" 2> /dev/null`
				return if path.empty?
				items ||= [] 
				executable = Executable.new(path.strip, :short)				 
				executable.history << self
				items << executable
				#command = command[/aliased to (.*)$/]
				options = parts[1..-1].reject(&:empty?)
				items << options.map{|part| 
					Option.new part} unless options.empty?
			when Enumerable
				items = input
		end
		super items, items.join#("")
	end
	def add; COMMAND.content = @items; end
	def content
		LOG.debug "command #{@items.map(&:name).join ' '}"
		@items.first.history << self
		if (object = @items.last).is_a? Entry 
#			default = @items.[
			object.class.default ||= Command.new @items[0..-2] 
		end
		[ `#{@items.map(&:name).join ' '} 2>/dev/null` ]
	end
end

class Option < Item
	attr_reader :description
	def initialize outline, description=""
		#@type = "-"
		#/(?<name>-+\w+)(?<delimiter>[ =])(?<parameter>.*)/.match(option).to_h)
		@name, @delimiter, @parameter = /(--?[[:alnum:]]*)([ =]?)(.*)$/.match( outline )[1..3]
		@description = description#.colored :description
		super @name, @name[1..-1]
	end
	#def image #long=false#x=nil, y=nil, area
		#@name[0..9].ljust(10).draw \
	#	super +	{ description: " " + @description }
		#(long ?  [" " + @description] : [] )
	#end
	def primary; add;	end
	#def add#content
	#	COMMAND.add self 
	#	nil #[]
	#end	
end

class User < Item
	def initialize name=ENV["USER"]
		super name
		#@type = "@"
	end
	#def content;	end
end
class Host < Item
	def initialize name=(`hostname`.strip or "localhost")
		super name
		#@type = ":"
		#@shape = //
		#if /\w+\.(?:gg|de|com|org|net)/.match letter
	end
	#def content	end
end
class Type < Item
	def initialize klass, name=klass.to_s.downcase
		super name
		#@type = "?"
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
		#@type = "+"
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
		#@type = " "
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
#	def initialize name
#		super name
		#@type = " "
#	end
end


	
