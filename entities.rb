# ORB - Omnipercipient Resource Browser
# 
# 	Items
#
# copyright 2017 kilian reitmayr
require "sequel"
require "helpers.rb"
class Item < Sequel::Model
	class << self; attr_accessor :id; end
	def self.type; self.id ||= Type[ long: self.to_s ];end

	plugin :timestamps, create: :time, update: :time
  plugin :single_table_inheritance, :type_id, model_map: 
  	Hash[ ([nil]+TYPE.keys).each_with_index.entries ].invert	  	  #many_to_one :type, key: :type_id, class: self
  many_to_many :items, class: self, join_table: :relations, 
  	left_key: :first_id, right_key: :second_id
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
	def find args
		@items = args.delete( :items ) if args[:items]
		super args
	end
	def to_s; short ? short : long; end
	def color; (super or self.class.type.color).to_sym; end
	def length; to_s.length; end
	#def type;	Type[ long: self.class.to_s ]; end	
	def content; end
	def description; extra or "";	end
	def add; COMMAND.add self; end
	def rename; short = COMMAND.getstr; save; end
	def action id=KEY_TAB
		#LOG.debug "action #{id}"
		case id
			when KEY_TAB, ONE_FINGER
				self.class.type.actions( self ).first.action
			when KEY_SHIFT_TAB, TWO_FINGER
				[ self.class.type.actions( self ) ]#.map{ |action|
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
		super long: name
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
class Text < Item; end
class Word < Text; end
#class Section < Text
#	def content; [ extra ];	end
#end
class Entry < Item
	def initialize args #path, short=nil#path#.split("/")[-1]
		args[:short] = args[:long].split("/")[-1] if 
			args[:short] == :name
		super args #path.path, short#.gsub /$\//, ''
	end
	def description 
		extra ||= `ls -dalh #{long} 2>/dev/null`.strip
		long + " " + extra
	end
end
class Directory < Entry
	def content 
		files,directories = [],[] #@entries = { right: [], down: [] }
		`file -i #{long}/*`.each_line do |line|

			entry = line.entry
    	(entry.is_a?(Directory) ? directories : files ) << 
    		entry if entry
    end
		[directories, files]
	end
end

class Executable < Entry
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
			  LOG.debug "desc :#{long}"
				extra = whatis.lines.first[23..-1].strip
			end
			#save
			#extra
		end	
	end 
end
class Textfile < Entry
	def content;super;[long.read];end
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
	def self.build input
		parts = input.partition(" ")
		return if (name = parts.shift).empty?
		
		# input.strip.split#(/\s(-{1,2}[^-]*)/)
		path=`which "#{ Shellwords.escape name }" 2> /dev/null`.strip
		#LOG.debug "cbuild #{name} #{path}"
		input = [ Executable.find_or_create(
			long: (path.empty? ? name : path), 
			short: name) ]
		input += parts.last.parse false 
		self.find_or_create long: input.join, items: input
	end
	def extra; items.map(&:long).join ' '; end
	def add; COMMAND.content = items; end
	def with item; @item = item; self; end 
	def content
		LOG.debug "command #{items.map(&:long).join ' '}"
	  parts = items
	  last = parts.pop unless 
	  	parts.last.is_a?(Option) or parts.size == 1
		command = last ? Command.find_or_create( 
			long:parts.join, items:parts ) : self
		parts.first.add_history command
		last.type.add_history command if last			
		parts += @item or last or []
		[ `#{parts.map(&:long).join ' '} 2>/dev/null` ]
	end
end

class Option < Item
	def action; add; end
	#def initialize outline, description=""
		#@type = "-"
		#/(?<name>-+\w+)(?<delimiter>[ =])(?<parameter>.*)/.match(option).to_h)
	#	long, @delimiter, @parameter = /(--?[[:alnum:]]*)([ =]?)(.*)$/.match( outline )[1..3]
	#	extra = description#.colored :description
	#	super long, long[1..-1]
		#default "add"
	#end
end

class User < Item; end
class Host < Item; end
