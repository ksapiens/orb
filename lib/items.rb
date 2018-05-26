# 	 ORB - Omniscient Resource Browser, Items
#    Copyright (C) 2018 Kilian Reitmayr <reitmayr@gmx.de>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License, version 2 
# 	 as published by the Free Software Foundation
#    
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.	
#

class Item < Sequel::Model #element feature bit piece detail entry point atom thing component molecule fragment grain dot spot particle
	plugin :timestamps, create: :time, update: :time
  plugin :single_table_inheritance, :type#, model_map: 
  	#Hash[ ([nil]+TYPE.keys).each_with_index.entries ].invert
	many_to_one :default, key: :default_id, class: self
  many_to_many :items, class: self, join_table: :relations, 
  	left_key: :first_id, right_key: :second_id
	def self.descendants
  	ObjectSpace.each_object(Class).select{|klass| klass < self}+
  	[self]
  end
	def self.type; @type ||= Type[ long: self.to_s ];end	

  alias :history :items 
  alias :add_history :add_item 
	attr_accessor :x, :y, :detail
	def create args;
		@items = args.delete( :items ) if args[:items]
		super args;	end
	def initialize args
	#args[:type_id] = (TYPE.keys.index self.class.to_s.to_sym) + 1
		@view ||= 0
		@items = args.delete( :items ) if args[:items]
		super args;	end
	def save args={}
		#self.class[long:long] or begin
			print '.' if FIRST
			me = super args; 
			@items.each{ |item| me.add_item(
				item.id ? item : item.save) } if @items; 
			@items = nil; me	
		#end
	end
	def find args
		#@items = args.delete( :items ) if args[:items]
		super args;	end
	def to_s; (short or long); end
	def long;super.start_with?("!ruby:") ? eval(super[6..-1]) : super; end
	def type; self.class.type; end
	def color; (super or type.color).to_sym; end
	def default; (super or type.default).for(self); end
	def length; to_s.length; end
	#def type;	Type[ long: self.class.to_s ]; end	
	def draw area, highlight=false
		area.draw (area.raw? ? long : to_s), x:x, y:y, color:color, 
			highlight:highlight
	end
	#def more; views[ (@view or 0) ] or ""; end
	#def cycle; @view = @view.cycle NEXT,0,views.count; end
	#def views; [extra, (long if short), 
	#	head ||= long.read(30)].compact; end
	def description;(extra or ""); end
	def actions;([type, default] + %w[content insert rename edit].map{ |name| Action[long:name].for self } + 
		type.history.map{ |action| action.for self }).uniq ;end
	def symbol; super or self.class.type.symbol; end
	#def symbol; long == "Type" ? super : self.class.type.symbol; end
	def insert; COMMAND.add self.dup; nil; end
	def rename; echo; short = COMMAND.getstr; noecho; save; end
	def stack; self.update in_stack:true;self; end
	def edit; end
	#def flag; self.symbol="<"; save;nil; end
	def record; key = getch;save; end
	def detail args# = {}
		LOG.debug args
		@detail.work if @detail
		@detail ||= Writer.new( args.merge( prefix:" < ", content:description) ); end
	def content; end; 
	def set_default; end
end
class Type < Item
#	def content; [ Add.new(long:long) ] + eval(long).all; end
	#def symbol; ;end
	def content; eval(long).all; end
	def insert id=nil
		#COMMAND#.content = [ Text.new(long.to_s + " : ") ]
		echo
		item = eval(long).new(long:COMMAND.getstr)
		STACK << item
		item.content
	end  
end

class Activity < Item; 
	def flag; symbol=(@view = !@view) ? "<" : type.symbol;save;end
	def content; run; end
	def actions;[Action[long:"set_default record"].for(self)] + super; end
	def set_default; @item.type.default = self; end
end
class Action < Activity
	def for item; @item = item; self; end
	def run; @item.instance_eval long; end
end
class Command < Activity
	def self.create args
		last = args[:items].pop unless 
	  	args[:items].last.is_a?(Option) or 
	  	args[:items].size == 1
		args[:long] = args[:items].join unless args[:long]
		command = self[ long:args[:long] ] or begin
			#args[:items].first.add_history( 
	  	first = args[:items].first
			command = super args 
			#)Command.find_or_create(long:parts.join,items:parts)
			first.add_history command
			#last.add_history command if last
			last.type.add_history command if last
			command
		end
		command.for last
	end

	def extra; items.map(&:long).join ' '; end
	#def insert; COMMAND.content = items;COMMAND.work; end
	def for item
		return self unless item
		@combined = items + [@item = item]
		#long = items.join; 
		self
	end 
	def run; self; end
	def string #LOG.debug "command: " +
		(@combined or items).map(&:long).join ' '
	end
end



#class Add < Item
#end
class Text < Item;end
class Word < Text; end
class Boolean < Text; 
	def edit;end
end
class Number < Text; end

class Entry < Item
	def initialize args #path, short=nil#path#.split("/")[-1]
		args[:short] = args[:long].split("/")[-1] if 
			args[:short] == :name
		super args #path.path, short#.gsub /$\//, ''
	end
	def description; super + ((" "+long if short) or ""); end
end
class Directory < Entry
	def content 
		`file -i #{long}/*`.each_line.map{ |line| 
			next unless match = /^(.+):\s*(.+)\/(.+);.*$/.match(line)
			name,type,sub = *match.captures
		  sub = "program" if name.executable? and
		  	(%w{directory symlink} & [type, sub]).empty?
		  type += "file" if type == "text" 
		  klass = Entry.descendants.select{ |c| [ sub, type, "entry" 
		  	].include? c.to_s.downcase }.first
		  klass.new(long:name,short: :name)
		  #[ sub, type, "entry" ].map{ |type| ( (eval type.capitalize).new(long:name,short: :name)) if Entry.descendants.include? type.capitalize }.compact.first 	  
		}.compact
	end
end

class Program < Entry
	def content 
		COMMAND.content.clear
		insert#COMMAND.add self
		manual = `COLUMNS=1000 man --nj --nh #{long} 2>/dev/null`
		options = manual.split(/^\s*(--?\w+)(\s*$)|(\s{3,})/ 
			).reject{|o| o.strip.empty? }
		#@page = Hash[*txt.gsub(/^ {7}/,"").split( 
		#	/(^[[:upper:]][[[:upper:]] ]{2,}$)/ )[1..-1]]
		#range = @page["OPTIONS"] || 
		#	@page["SWITCHES"] || 
		#	@page["DESCRIPTION"] 
		(	history + 
			options.each_with_index.map{ |name,index|	Option.new( 
				long:name.split(/,\s| or /).longest,extra:options[index+1]) if 
					name.start_with? "-" }.compact
		).uniq{ |entry| entry.long }
		#Hash[*range.split(/^(-+.{1,30})\n? {3,}/ ).map( &:strip)[1..-1]].map{ | outline, more | } +
		#		man.page.map{ |section ,content| 
		#			Section.new long: section, extra: content } ]
	end
	#def help;	[ `#{long} --help` ]; end	
	#def manual;	[ `man #{long}` ];	end	
end

class Option < Item
	def content; insert; end
	def short; long[1..-1]; end
end


class Textfile < Entry
	def content; long.read; end
end	
class Video < Entry; end
class Audio < Entry; end
class Image < Entry; end

class Special < Entry; end
class Symlink < Special; end
class Fifo <  Special; end
class Socketfile < Special; end
class Chardevice < Special; end

class Tag < Item
	def count; "#{items.size} entries"; end
	#def content; items; end
end

class User < Item; end
#class Email < Item; end
#class Phone < Item; end
class Url < Item; end
class Host < Item; end
class Form < Item; end
