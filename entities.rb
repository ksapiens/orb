# ORB - Omnipercipient Resource Browser
# 
# 	Items
#
# copyright 2016 kilian reitmayr
require "sequel"
require "helpers.rb"
class Item < Sequel::Model
	class << self; attr_accessor :symbol, :color, :default; end
	#attr_reader :long
	self.symbol = ""
	self.color = :white
	plugin :timestamps
  plugin :single_table_inheritance, :type#_id#, model_map: 
  #	Hash[ ([nil]+TYPE.keys).each_with_index.entries ].invert	  	  	#key_chooser: proc{|type| TYPE.keys.index type }
 # many_to_one :type, key: :type_id, class: self
  many_to_many :items, class: self, join_table: :relations, left_key: :first_id, right_key: :second_id
	#def self.descendants
  #	ObjectSpace.each_object(Class).select{ |klass| klass < self }
  #end
  alias :history :items 
	attr_accessor :x, :y
	def self.create args
		super args
		@items.each{ |item| add_item item } if @items
	end
	def initialize args
		@items = args.delete( :items ) if args[:items]
		super args
	end
#	def save
		#item.add_items items if items
		#item
		#path.path, short#.gsub /$\//, ''
	#end
	#def add_items (objects)
#		super
#	end 
	def length; to_s.length; end
	def content; end
	def add; COMMAND.add self; end
	def action id=KEY_TAB
		#LOG.debug "action #{id}"
		case id
			when KEY_TAB, KEY_MOUSE
				eval actions.first.to_s #primary				
			when KEY_SHIFT_TAB
				[ actions ] #list #secondary
			when KEY_CTRL_A
				add
			when KEY_CTRL_R
				rename
		end
	end
	def type
		Type.find_or_create long:super #type_id #
	end
	
	def actions
		@actions or begin
			@actions = %w[ content _open add rename ].map{ |name| 
				Action.new name, self } + type.history
		end
	end
	def to_s; short ? short : long; end
	#def initialize args #path, 
		#short="s"#path#.split("/")[-1]
		#args[:type_id] = (TYPE.keys.index self.class.to_s.to_sym) + 1
	#	super args #path.path, short#.gsub /$\//, ''
	#end
		
	#def has? variable; instance_variables.include? variable; end 
	def _open		
		return unless command = self.default
		command.add
		self.add
	end
	def rename; short = COMMAND.getstr; save; end
	def default action
		@actions.unshift(Action.new action, self).uniq!
	end
	def description
		extra or ""
	end
end
class Type < Item
	self.color = :cyan
	self.symbol = "?"
	#alias :symbol :short 
	def content
		[ Add.new(@long) ] + 
		 eval( long + ".all" ) 
			#$stack.content.select{|item| item.is_a? @name } ]
	end  
end
class Action < Item
	self.color = :red
	self.symbol = "!"
	def initialize name, item
		@name = name
		@item = item
		super long:name
	end
	def action id=nil 
		@item.instance_eval @name
	end
end
class Add < Item
	self.color = :bright
	self.symbol = "+"	
	def action id=nil
		COMMAND.content = [ Text.new(@long.to_s + " : ") ]
		item = eval(@long).new(long:COMMAND.getstr)
		$stack << item
		item.content
	end
end
class Text < Item; self.color = :bright; end
class Word < Text; end
class Section < Text
	self.symbol = " "
	def content; [ extra ];	end
end

class Entry < Item
	self.symbol = "/"
	self.color = :orange
	def initialize args #path, short=nil#path#.split("/")[-1]
		args[:short] = args[:long].split("/")[-1] if 
			args[:short] == :short
		super args #path.path, short#.gsub /$\//, ''
	end
	def description #extra
		extra or begin
#			if (whatis = `whatis #{@name} 2>/dev/null`).empty? 
			extra = `ls -dalh #{@name} 2>/dev/null`
#			else 
#				extra = whatis.lines.first[23..-1]; end
			save
			extra
		end	
	end
end
class Directory < Entry
	self.color = :yellow
	#def initialize path, short
	#	super path, short
	#	default "content"
	#end
	def content 
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
	
	self.color = :red
	#def open; content; end
	#def initialize path, short
	#	super path, short
	#	@history = []
	#	default "content"
	#end
	def content 
		COMMAND.content.clear
		COMMAND.add self
		#man = ManPage.new(long)
		#if man.page
		#	[[Collection.new( long:"history", items:@items )] +
		#		man.options.map{ | outline, description |	Option.new( 
		#			long: outline.split(",").last, extra: description) } +
		#		man.page.map{ |section ,content| 
		#			Section.new long: section, extra: content } ]
		#else [ `COLUMNS=1000 #{long} --help` ];end
		[ `COLUMNS=1000 #{long} --help` ]
	end
	def description #extra
		extra or begin
			if (whatis = `whatis #{long} 2>/dev/null`).empty? 
				super
			else 
				extra = whatis.lines.first[23..-1]
			end
			save
			extra
		end	
	end 
end

class Textfile < Entry
	self.color = :white
	def content;super;[long.read];end
end	
class Video < Entry; self.color = :cyan ;end
class Audio < Entry; self.color = :blue ;end
class Image < Entry; self.color = :green;end

class Special < Entry; self.color = :magenta; end
class Symlink < Special; end
class Fifo <  Special; end
class Socketfile < Special; end
class Chardevice < Special; end

class Collection < Item
	self.color = :green
	self.symbol = "*"
	def description; "#{items.size} entries"; end
	def content; [items]; end
end
class Container < Collection
	def content
		result = [] 
		for item in items
		  item.content.each_with_index{ |value,index|
				result[index] ||= []
				result[index] += value }
		end
		result
	end
end
class Command < Collection
	self.color = :magenta
	self.symbol = ">"
	def self.create input
		case input
			when String 
				parts = input.strip.split(/\s(-{1,2}[^-]*)/)
				return if parts.empty?
				path = `which "#{ Shellwords.escape parts[0].split[0] }" 2> /dev/null`
				return if path.empty?
				executable = Executable.find_or_create(long: path.strip,
					short: :short)				 
				#executable.add_item self
				items = [executable]
				#items <<  executable
				#command = command[/aliased to (.*)$/]
				options = parts[1..-1].reject(&:empty?)
			  options.each{ |part| 
					items << Option.find_or_create(long:part) } unless options.empty?
			when Enumerable
				items <<  input
		end
		super long: items.join, items: items
	end
	def extra; items.map(&:long).join ' '; end
	def add; COMMAND.content = items; end
	def content
		LOG.debug "command #{items.map(&:name).join ' '}"
		items.first.add_item self
		if (object = items.last).is_a? Entry 
#			default = @items.[
			object.type.default ||= Command.new items[0..-2] 
		end
		[ `#{items.map(&:long).join ' '} 2>/dev/null` ]
	end
end

class Option < Item
	self.color = :blue
	self.symbol = "-"
#	attr_reader :description
	#def initialize outline, description=""
		#@type = "-"
		#/(?<name>-+\w+)(?<delimiter>[ =])(?<parameter>.*)/.match(option).to_h)
	#	long, @delimiter, @parameter = /(--?[[:alnum:]]*)([ =]?)(.*)$/.match( outline )[1..3]
	#	extra = description#.colored :description
	#	super long, long[1..-1]
		#default "add"
	#end
	#def primary; add;	end
end

class User < Item
	self.color = :blue
	self.symbol = "@"
#	def initialize name=ENV["USER"]
#		super name
#	end
end
class Host < Item
	self.color = :green
	self.symbol = ":"
#	def initialize args
#		args[:name] = (`hostname`.strip or "localhost")
#		super args
		#if /\w+\.(?:gg|de|com|org|net)/.match letter
#	end
end
