# ORB - Omnipercipient Resource Browser
# 
# 	Items
#
# copyright 2016 kilian reitmayr

class Item #< String
	attr_reader :letters, :type#
	attr_accessor :x, :y#, :area 
	def to_s; @letters; end
	#def inspect; to_s; end
	def image long=false, type=true 
		#LOG.debug self
		[ (@type.colored( :dark ) if type),
		@letters.colored( color )]
	end
	def width; @letters.length + 1; end
	def color 
		name = self.class
		name = name.superclass until 
			COLORS.include? name.to_s.downcase.to_sym 
		name.to_s.downcase.to_sym
	end
	def initialize letters=''; 
		@type ||= ' '
		@letters ||= letters#.colored color
	end
	def primary; end
end

class Entry < Item
	attr_reader :path#, :shape
	def initialize path, letters=path.split("/")[-1]
		@type = "/"
		#@shape = /(?:[\s=])\/\S*/
		@path = path
		super letters#.gsub /$\//, ''
	end
	#def eql? (object)
	#	path == object.path || !path
	#end
end
class Directory < Entry
	def primary #restore=nil
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
		@history = []
		super path
	end
	def primary area=nil
		#if area == COMMAND		
		#else
			COMMAND.content = [self]  #@letters 
			man = ManPage.new(@letters)
			if man.page
				[ @history + man.page.map{ |section ,content| 
						Section.new section, content },
			  	man.options.map{ | outline, description |	
						Option.new( outline.split(",").last, description) }
				]
			else [ `COLUMNS=1000 #{letters} --help` ];end
		#end
	end 
end
class Symlink < Entry; end
class Fifo < Entry; end
class Socket < Entry; end
class Chardevice < Entry; end
class Textfile < Entry
	def primary;[path.read];end
end	

class Container < Item
	def initialize items, letters
		@items = items
		super letters
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

#class Special < Item; end
class Option < Item
	def width; image.join.length; end
	def initialize outline, description=""
		
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
		[]
	end	
end
class Command < Item
	attr_accessor :sequence
	def initialize input
		case input
			when String 
				parts = input.strip.split(/\s(-{1,2}[^-]*)/)
				return if parts.empty?
				
				#path = `#{shell} -c "which #{parts[0].split[0]} 2> /dev/null"`
				path = `which "#{Shellwords.escape parts[0].split[0]}" 2> /dev/null`
				return if path.empty?
				@sequence ||= [] 
				command = Executable.new(path.strip)				 
				
				command.history << self
				@sequence << command 
				#command = command[/aliased to (.*)$/]
				options = parts[1..-1].reject(&:empty?)
				LOG.debug "com #{options}"
				@sequence << options.map{|part| 
					Option.new part} unless options.empty?
							
			when Enumerable
				@sequence = input
		end
		
		@type = ">"					
		super @sequence.join ""
		
	end
	def image long=false 

		[@type] + @sequence.map{|i| i.image[-1] }				
	end
	def primary
		#COMMAND.content = @sequence
		@sequence.first.history << self
		[ `#{@sequence.join ' '}` ]
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
		@content = content
		super letters
	end
	def primary #restore
		#$world.pop
		[ @content ]
	end
end
class Text < Item
@type = ''
end
class Word < Item
#	def initialize letters
#		@type = " "
#		super letters
#	end
end


	
