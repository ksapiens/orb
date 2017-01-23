# ORB - Omnipercipient Resource Browser
# 
# 	Items
#
# copyright 2016 kilian reitmayr
require "sequel"
require "helpers.rb"

class Item < Sequel::Model
	plugin :timestamps
  plugin :single_table_inheritance, :type_id, model_map: 
  	Hash[ ([nil]+TYPE.keys).each_with_index.entries ].invert	  	  	#key_chooser: proc{|type| TYPE.keys.index type }
  many_to_one :type, key: :type_id, class: self
  many_to_many :items, class: self, join_table: :relations, 
  	left_key: :first_id, right_key: :second_id
	#def self.descendants
  #	ObjectSpace.each_object(Class).select{ |klass| klass < self }
  #end
	#alias :name :long 
	#alias :description :extra
	attr_accessor :x, :y#, :alias
	def create args
		i = args.delete( :items ) if args[:items]
		super args #path.path, short#.gsub /$\//, ''
		add_items i
	end
	def initialize args #path, 
		#short="s"#path#.split("/")[-1]
		args[:type_id] = (TYPE.keys.index self.class.to_s.to_sym) + 1
		super args #path.path, short#.gsub /$\//, ''
	end
		#@actions = %w[ content _open add rename ].map{ |name| 
		#	Action.new name, self } + type.history

	def to_s; short ? short : long; end
	def length; to_s.length; end
	#def has? variable; instance_variables.include? variable; end 
	def _open		
		return unless default = type.default
		default.add
		self.add
	end
	def add_items (objects)
		objects.each{ |item| add_item item } 
	end 
	def content; end
	def add; COMMAND.add self; end
	def rename; short = COMMAND.getstr; end
	def action id=KEY_TAB
		#LOG.debug "action #{id}"
		case id
			when KEY_TAB, KEY_MOUSE
				eval @actions.first.to_s #primary				
			when KEY_SHIFT_TAB
				[ @actions ] #list #secondary
			when KEY_CTRL_A
				add
			when KEY_CTRL_R
				rename
		end
	end
	def default action
		@actions.unshift(Action.new action, self).uniq!
	end
end

class Action #< Item
	def initialize name, item
		@item = item
		@name = name
		#super name
	end
	def action id=nil #primary
		@item.instance_eval @name
	end
end

class Entry < Item
	def initialize args #path, short=nil#path#.split("/")[-1]
		args[:short] = args[:long].split("/")[-1] if 
			args[:short] == :short
		super args #path.path, short#.gsub /$\//, ''
	end
	def extra
		super or begin
			if (whatis = `whatis #{@name} 2>/dev/null`).empty? 
				extra = `ls -dalh #{@name} 2>/dev/null`
			else 
				extra = whatis.lines.first[23..-1]; end
			save
		end	
	end
end
class Directory < Entry
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
	alias :history :items
	#def open; content; end
	#def initialize path, short
	#	super path, short
	#	@history = []
	#	default "content"
	#end
	def content 
		COMMAND.content.clear
		COMMAND.add self
		man = ManPage.new(long)
		if man.page
			[[Collection.new( "history", items )] +
				man.options.map{ | outline, description |	Option.new( 
					long: outline.split(",").last, extra: description) } +
				man.page.map{ |section ,content| 
					Section.new long: section, extra: content } ]
		else [ `COLUMNS=1000 #{long} --help` ];end
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
		result = [] # { right: [], down: [] }
		for item in items
		  item.content.each_with_index{ |value,index|
				result[index] ||= []
				result[index] += value }
		end
		result
	end
end
class Command < Collection
	def initialize input
		case input
			when String 
				parts = input.strip.split(/\s(-{1,2}[^-]*)/)
				return if parts.empty?
				path = `which "#{ Shellwords.escape parts[0].split[0] }" 2> /dev/null`
				return if path.empty?
				executable = Executable.new(long: path.strip,
					short: :short)				 
				executable.add_item self
				add_item executable
				#command = command[/aliased to (.*)$/]
				options = parts[1..-1].reject(&:empty?)
			  options.each{ |part| 
					add_item Option.new(part) } unless options.empty?
			when Enumerable
				add_items input
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
#	attr_reader :description
	def initialize outline, description=""
		#@type = "-"
		#/(?<name>-+\w+)(?<delimiter>[ =])(?<parameter>.*)/.match(option).to_h)
		long, @delimiter, @parameter = /(--?[[:alnum:]]*)([ =]?)(.*)$/.match( outline )[1..3]
		extra = description#.colored :description
		super long, long[1..-1]
		#default "add"
	end
	#def primary; add;	end
end

class User < Item
#	def initialize name=ENV["USER"]
#		super name
#	end
end
class Host < Item
#	def initialize args
#		args[:name] = (`hostname`.strip or "localhost")
#		super args
		#if /\w+\.(?:gg|de|com|org|net)/.match letter
#	end
end
class Add < Item
	def action
		COMMAND.content = [ Text.new(@name.to_s + " : ") ]
		item = @name.new(COMMAND.getstr)
		$stack << item
		item.content
	end
end
class Type < Item
	alias :symbol :short 
	def content
		[ [ Add.new(@name) ] + 
			$stack.content.select{|item| item.is_a? @name } ]
	end  
end
class Section < Item
	def content; [ extra ];	end
end
class Text < Item; end
class Word < Item; end

