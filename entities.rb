# ORB - Omnipercipient Resource Browser
# 
# 	Items
#
# copyright 2017 kilian reitmayr
require "sequel"
require "helpers.rb"
class Item < Sequel::Model
	#class << self; attr_accessor :id; end
	#def self.default; @default ||= self.type.default; end
	plugin :timestamps, create: :time, update: :time
  plugin :single_table_inheritance, :type#, model_map: 
  	#Hash[ ([nil]+TYPE.keys).each_with_index.entries ].invert
	many_to_one :default, key: :default_id, class: self
  many_to_many :items, class: self, join_table: :relations, 
  	left_key: :first_id, right_key: :second_id

	def self.descendants
  	ObjectSpace.each_object(Class).select{ |klass| klass < self }
  end
	def self.type; @type ||= Type[ long: self.to_s ];end	
	
  alias :history :items 
  alias :add_history :add_item 
	attr_accessor :x, :y
	def initialize args
	#args[:type_id] = (TYPE.keys.index self.class.to_s.to_sym) + 1
		print "."		
		@view ||= 0
		@items = args.delete( :items ) if args[:items]
		super args;	end
	def save
		me = self.class[long:long] 
		me ||= super
		@items.each{ |item| me.add_item item.save } if @items
		me		
	end
	def find args
		@items = args.delete( :items ) if args[:items]
		super args;	end
	def to_s; (short or long); end
	def long; super[0] == "!" ? eval(super[1..-1]) : super; end
	def color; (super or self.class.type.color).to_sym; end
	def default; super or self.class.type.default; end
	def length; to_s.length; end
	#def type;	Type[ long: self.class.to_s ]; end	
	def content; end
	def more; views[ (@view or 0) ] or ""; end
	def cycle; @view = @view.cycle NEXT,0,views.count; end
	def views; [extra, (long if short), 
		@output ||= long.read(30)].compact; end
	
	def symbol; super or self.class.type.symbol; end
	def add; COMMAND.add self; end
	def rename; short = COMMAND.getstr; save; end
	def stack;(in_stack = true; save) unless in_stack;end
	def action id=KEY_TAB
		#LOG.debug "action #{id}"
		case id
			when KEY_TAB, ONE_FINGER
				(default or self.class.type.default).for(self).action id
			when KEY_SHIFT_TAB, TWO_FINGER
				[ #self.class.actions( self ) +
					self.class.type.history.map{ |action| action.for self}]
			when KEY_CTRL_A 
				add
			when KEY_CTRL_R 
				rename
		end
	end
end
class Type < Item
	#alias :symbol :short 
	#alias :actions :items
	#def to_s; long; end
	def content
		[[ Add.new(long:long) ] + 
		 eval(long).all ]
	end  
end
class Action < Item
	def for item; @item = item; self; end
	def action id=nil; @item.instance_eval long; end
end
class Add < Item
	def action id=nil
		COMMAND.content = [ Text.new(long.to_s + " : ") ]
		item = eval(long).new(long:COMMAND.getstr)
		STACK << item
		item.content
	end
end
class Text < Item; end

class Word < Text; end
class Boolean < Text; 
	def toggle
		end
end

class Number < Text; end


class Entry < Item
	def initialize args #path, short=nil#path#.split("/")[-1]
		args[:short] = args[:long].split("/")[-1] if 
			args[:short] == :name
		super args #path.path, short#.gsub /$\//, ''
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
		manual = `COLUMNS=1000 man --nj --nh #{long} 2>/dev/null`
		options = manual.split(/^\s*(--?\w+)(\s*$)|(\s{2,})/ 
			).reject{|o| o.strip.empty? }
		#@page = Hash[*txt.gsub(/^ {7}/,"").split( 
		#	/(^[[:upper:]][[[:upper:]] ]{2,}$)/ )[1..-1]]
		#range = @page["OPTIONS"] || 
		#	@page["SWITCHES"] || 
		#	@page["DESCRIPTION"] 
		[	history + 
			options.each_with_index.map{ |name,index|	Option.new( 
				long:name.split(/,\s| or /).longest,extra:options[index+1]) if 
					name.start_with? "-" }.compact
		].uniq{ |entry| entry.long }
		#Hash[*range.split(/^(-+.{1,30})\n? {3,}/ ).map( &:strip)[1..-1]].map{ | outline, more | } +
		#		man.page.map{ |section ,content| 
		#			Section.new long: section, extra: content } ]
		#else [ `COLUMNS=1000 #{long} --help` ];end
	end
	#def help;	[ `#{long} --help` ]; end	
	#def manual;	[ `man #{long}` ];	end	
	#def more #extra
		#extra ||= (`COLUMNS=#{ENV["COLUMNS"].to_i + 23} whatis #{short} 2>/dev/null`.lines.first or "")[23..-1] or super
#		extra or begin
#			if (whatis = `whatis #{long} 2>/dev/null`).empty? 
#				extra = super
#			else 
			  #LOG.debug "desc :#{long}"
#				extra = whatis
#			end
			#save
			#extra
		#end	
	#end 
end
class Textfile < Entry
	def content; [long.read]; end
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
	def more; "#{items.size} entries"; end
	def content; [items]; end
end
class Command < Collection
	def self.create args
	#	parts = 
		args[:long] = args[:items].join unless args[:long]
		self[ long:args[:long] ] or begin
			#args[:items].first.add_history( 
	  	first = args[:items].first
	  	last = args[:items].last unless 
	  		args[:items].last.is_a?(Option) or 
	  		args[:items].size == 1
			command = super args #)Command.find_or_create(long:parts.join,items:parts)
			first.add_history command
			last.class.type.add_history command if last
			command
		end
	end
	def extra; items.map(&:long).join ' '; end
	def add; COMMAND.content = items;COMMAND.work; end
	def for item
		@combined = items[0..-2]+[item]
		long=items[0..-2].join; self
	end 
	def content
		LOG.debug "command #{(@combined or items).map(&:long).join ' '}"
		#parts << (@item or last) if @item or last 
		#@item ||= []
	  #if @item
		[`#{(@combined or items).map(&:long).join ' '} 2>/dev/null`]
	end
end

class Option < Item
#	def self.actions item
#			[ Action[ long:"add"].for(item) ] 		
#	end
	def action id=nil; add; end
	def short; long[1..-1]; end
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
