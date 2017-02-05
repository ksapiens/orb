# ORB - Omnipercipient Resource Browser
# 
# 	Items
#
# copyright 2016 kilian reitmayr
require "sequel"
require "helpers.rb"
class Item < Sequel::Model
	class << self; attr_accessor :symbol, :color, :default; end
	plugin :timestamps, create: :time, update: :time
  plugin :single_table_inheritance, :type_id, model_map: 
  	Hash[ ([nil]+TYPE.keys).each_with_index.entries ].invert	  	  	  #many_to_one :type, key: :type_id, class: self
  many_to_many :items, class: self, join_table: :relations, left_key: :first_id, right_key: :second_id
	def self.descendants
  	ObjectSpace.each_object(Class).select{ |klass| klass < self }
  end
  alias :history :items 
  alias :add_history :add_item 
	attr_accessor :x, :y
	def self.create args
		items = args.delete( :items ) if args[:items]
		instance = super args
		LOG.debug items
		items.each{ |item| instance.add_item item.save } if items
		instance
	end
	def initialize args
		#args[:type_id] = (TYPE.keys.index self.class.to_s.to_sym) + 1
		@items = args.delete( :items ) if args[:items]
		super args
	end
	def save
		@items.each{ |item| add_item item.save } if @items
		super
	end
	def to_s; short ? short : long; end
	def color; (super or type.color).to_sym; end
	def length; to_s.length; end
	def content; end
	def add; COMMAND.add self; end
	def action id=KEY_TAB
		#LOG.debug "action #{id}"
		case id
			when KEY_TAB, ONE_FINGER
				type.actions( self ).first.action
			when KEY_SHIFT_TAB, TWO_FINGER
				[ type.actions( self ) ]#.map{ |action|
						#if action.is_a? Command
							#action.with self ]
						#else
						#	action.item = self
						#end ] 
			when KEY_CTRL_A 
				add
			when KEY_CTRL_R 
				rename
		end
	end
	def type;	Type[ long: self.class.to_s ]; end	
	#def actions
	#	@actions or begin
	#		@actions = %w[ content add rename ].map{ |name| 
	#			Action.new name, self } + type.history
	#	end
	#end

	#def _open		
	#	return unless command = self.default
	#	command.add
	#	self.add
	#end
	def rename; short = COMMAND.getstr; save; end
	#def default #action
	#	@default or begin
	#		@default = Action.new 'content', self
	#	end
		#@actions.unshift(Action.new action, self).uniq!
	#end
	def description; extra or "";	end
end
class Type < Item
	alias :symbol :short 
	#alias :actions :items
	def to_s; long; end
#	def default item
#		actions.first
#	end
	def actions item
		%w[ content add rename ].map{|name| Action.new name,item } +
		history.map{ |command| command.with item }
	end

	def content
		[[ Add.new(long:long) ] + 
		 eval( long + ".all" ) ]
	end  
end
class Action < Item
	def initialize name, item
		#@name = name
		@item = item
		super long:name
	end
	def action id=nil 
		@item.instance_eval long 
	end
	
end
class Add < Item
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
	def content; [ extra ];	end
end

class Entry < Item
	def initialize args #path, short=nil#path#.split("/")[-1]
		args[:short] = args[:long].split("/")[-1] if 
			args[:short] == :name
		super args #path.path, short#.gsub /$\//, ''
	end
	def description #extra
		#extra or begin
		extra = `ls -dalh #{long} 2>/dev/null` unless extra
		long + " " + extra
		#	save
		#	extra
		#end	
	end
end
class Directory < Entry
	self.color = :yellow
	def content 
		files,directories = [],[] #@entries = { right: [], down: [] }
		`file -i #{long}/*`.each_line do |line|
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
				extra = super
			else 
				extra = whatis.lines.first[23..-1]
			end
			#save
			extra
		end	
	end 
end

class Textfile < Entry
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
#	self.color = :magenta
#	self.symbol = ">"
	def self.build input
		parts = input.strip.split#(/\s(-{1,2}[^-]*)/)
		#return if parts.empty?
		name = parts.shift
		path=`which "#{ Shellwords.escape name }" 2> /dev/null`.strip
		#return if path.empty?
		input = [ Executable.find_or_create(
			long: (path.empty? ? name : path), 
			short: name) ]
		#options = parts[1..-1].reject(&:empty?)
		input += parts.map{ |part| part.parse } #or []
		#when Enumerable
		#	items = [input]

		self.create long: input.join, items: input
	end
	def extra; items.map(&:long).join ' '; end
	def add; COMMAND.content = items; end
	def with item; @item = item; self; end 
	def content
		LOG.debug "command #{items.map(&:name).join ' '}"
	  parts = items
	  last = parts.pop unless 
	  	parts.last.is_a?(Option) or parts.size == 1
		command = last ? Command.find_or_create( 
			long:parts.join, items:parts ) : self
		parts.first.add_history command
		last.type.add_history command if last			
		parts += @item ? @item : last
		[ `#{parts.map(&:long).join ' '} 2>/dev/null` ]
	end
end

class Option < Item
	def action; add; end
#	self.color = :blue
#	self.symbol = "-"
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
#	self.color = :blue
#	self.symbol = "@"
#	def initialize name=ENV["USER"]
#		super name
#	end
end
class Host < Item
#	self.color = :green
#	self.symbol = ":"
#	def initialize args
#		args[:name] = (`hostname`.strip or "localhost")
#		super args
		#if /\w+\.(?:gg|de|com|org|net)/.match letter
#	end
end
