#!/usr/bin/env ruby

# ORB - Omnipercipient Resource Browser
# 
# 	Launcher
#
# copyright 2017 kilian reitmayr
$LOAD_PATH  << __dir__ #"#{File.dirname __FILE__}/."
#require 'pry'
require 'logger'
require 'sequel'
require "helpers.rb"

"~/.orb".mkdir unless "~/.orb/".exists?
"./config.default".copy "~/.orb/config" unless 
	"~/.orb/config".exists?
eval "~/.orb/config".read
LOG = Logger.new("orb.log")
FIRST = !"~/.orb/db.sqlite".exists? 
DB = Sequel.sqlite "~/.orb/db.sqlite".path
#DB.loggers << LOG

if FIRST	
	puts "first run: data persistence"
	DB.create_table( :items ) do #objects
  	primary_key :id
  	foreign_key :default_id
  	String :type, size: 12 #meaning identity  

		String :symbol, fixed: true, size: 1
  	String :color #_id, :colors
  	
  	String :long #, :unique => true 
  	String :short
  	String :extra
  	
  	Integer :count
  	#String :found_in #file - for editing
  	#Integer :position
  	TrueClass :in_stack
  	DateTime :time
  	unique [ :long, :type ]
	end 
 	
	DB.create_table( :relations ) do
  	primary_key :id
  	foreign_key :first_id, :items
  	foreign_key :second_id, :items
	end 
end
require "entities.rb"
require 'view/terminal'
require "manual.rb"
require "writer.rb"

def debug?; $*.include? "-d"; end
def loop?; $*.include? "-l"; end
halt if debug?
LOADED = (__FILE__ != $0)
NEXT, PREVIOUS = 1, -1

if FIRST
	#fork do
	puts "creating essentials"
	DB.transaction do
		actions = %w[ content add rename set_default set_type_default].map{ |name| Action.create( long:name) }	
		TYPE.each{ |type,var| Type.create long:type, 
			short:type.downcase, symbol:var.first, items:actions[0..2],				 color:var[1], extra:var.last, default_id:1 }
	end; #fork do; 
	DB.transaction do	
		puts "creating known entries in PATH"
		for path in ENV["PATH"].split(":")-["."]
			puts path = path.path
			`whatis -l -s 1 #{path}/* 2>empty`.scan(
				/^(.+) \(1.*- (.+)$/).each do |values|
					Executable.create long:path +"/"+ values.first,
						short: values.first, extra:values.last rescue next
			end
		end
			
		puts "creating unknown entries in PATH"
		for line in "empty".read.lines
			Executable.create long:line[/^.+:/].chop, short: :name 
		end; "empty".rm	
		#log = ("~/.zsh_history").read.force_encoding(
		#	"Windows-1254").gsub /^:\s\d*:\d;/, '' if 
		#	"~/.zsh_history".exists?
		puts "parsing shell logs"
		log = ("~/.bash_history").read #if "~/.bash_history".exists?
		for line in log.split /[\n|]/
			parts = line.partition " "
			exe = Executable[short:parts.first]
			Command.create( items: [exe.stack]+	
				parts.last.parse ) if exe rescue next 
		end if log
	end#;end
	puts "creating basic objects"
	Type[ short:"type" ].stack
	Directory.create( 
		long: "!'.'.path", short: "current", in_stack: true)
	Directory.create( 
		long: "!ENV['HOME']", short: "home", in_stack: true )
	Directory.create( long: "/", short: "root", 
		extra: "beginning of the directory tree", in_stack: true )
	Textfile.create( long: "./help.txt".path, short: "help", extra:
	  "click or tap here or type 'help' and press TAB", in_stack: true )
#	%w[ ? current home root help ].each{ |item| item.save }
end

init unless LOADED

$world,$selection = [],[]
$focus,$choice,$counter = 2,0,0
$filter=""

$world = [ 
	(HEAD = Writer.new content:[
		User.new( long: "!ENV['USER']" ),
		Host.new( long: "!`hostname`.strip" ), 
		Directory.new( long: "!'.'.path")],
		#,short: "!'.'.path[1..-1]")],
		x: LEFT, y: 0, height:0, delimiter:'', selection:false),
	(COMMAND = Writer.new	prefix: ">", x: LEFT, 
		y: lines-1, height:0, delimiter:' ', selection:false),
	(STACK = Writer.new content: 
		Item.where( in_stack: true ).order(:time).reverse.all, 
	 	x: LEFT, delimiter:$/, selection:true ) ]

# main class
class ORB #< Window
	#def help
		#$stack << DEFAULT
	#	$world << Writer.new content: "help.txt".read
	#end
  def colortest
		clear
		COLOR.each_with_index do |color,i|
			setpos i,LEFT
			attron color_pair i
			addstr "#{color[0]} - #{color_content i}"
		end
		getch 
		clear
		$world.each( &:work )
	end
	def action id, x, y
		for area in $world
			if 	x.between?( area.left, area.right ) && 
					y.between?( area.top, area.bottom+1 )
				
				#LOG.debug "e: %s b: %s" % [mouse.eid, mouse.bstate ]
				area.action id, x - area.left, y - area.top
				break
			end
		end
	end
	def run
		loop do
			writer = $world[$focus].work
 			#$counter = 0
			$world.each( &:update )
#			$world.each( &:work )
    	input = getch #Event.poll 
			LOG.debug "input :#{input}"
			
    	case input
    		when KEY_MOUSE
    			mouse = getmouse
    			action mouse.bstate, mouse.x, mouse.y
				when KEY_ESC || KEY_EXIT
        	exit
				when KEY_F12
					colortest
				when KEY_F1
					help
				when KEY_F2
					halt
				when KEY_BACKSPACE
					$filter.chop!
					
				when KEY_NPAGE
					writer.move NEXT * writer.height
				when KEY_PPAGE
					writer.move PREVIOUS * writer.height
				when KEY_DOWN
					writer.move NEXT 
				when KEY_UP
					writer.move PREVIOUS
				when KEY_RIGHT
					writer.pass NEXT
				when KEY_LEFT
					writer.pass PREVIOUS
				when KEY_TAB, KEY_SHIFT_TAB, KEY_CTRL_A
					$filter.clear
					writer.action input#, *$selection[$choice]#
				when KEY_RETURN #KEY_ENTER || 
					COMMAND.action 
        when String
        	writer.page = 0
        	writer.choice = 0
        	$filter += input
    	end
    end
  end
begin
#		loop do 
			ORB.new.run 
#		end unless LOADED
end #while loop?
ensure
#	LOG.debug "ensure"
	use_default_colors()
  close_screen unless LOADED
end
