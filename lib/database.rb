#!/usr/bin/ruby
# 	 ORB - Omniscient Resource Browser, Database
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

#$LOAD_PATH << "#{File.dirname __FILE__}/lib/"

#require 'rubygems'
require 'sequel'
require 'logger'
#require 'shellwords'
#require 'digest/md5.so'
#require 'profile'
#THREADS = 4

DB = Sequel.sqlite 'default.sqlite'
#DB.loggers << Logger.new("tagger.log")
DBLOG = Logger.new("db.log")

DB.create_table( :types ) do #identity meaning 
  primary_key :id
  foreign_key :color_id, :colors
  foreign_key :item_id, :items
  String :name, :unique => true 
  String :shape
  Char :symbol
  
  Integer :count
end #unless DB.table_exists? :types

DB.create_table( :colors ) do 
  primary_key :id
  #foreign_key :field_id
  String :name
  Integer :red
  Integer :green
  Integer :blue  
end #unless DB.table_exists? :

DB.create_table( :items ) do #string object word 
  primary_key :id
  #foreign_key :entries_id, :items
  #foreign_key :mime_id, :mimes #, :size => 12
	foreign_key :type_id, :types
  String :long, :unique => true 
  String :short
  String :extra
  #String :md5, :size => 32 
  String :found_in #file
  Integer :position
  #Integer :size
  TrueClass :executable
end #unless DB.table_exists? :items
 
DB.create_table( :relations ) do
  primary_key :id
#  foreign_key :supported_id, :tags#, :on_delete => :cascade
#  foreign_key :available_id, :tags#, :on_delete => :cascade
  foreign_key :first_id, :items#, :on_delete => :cascade
  foreign_key :second_id, :items#, :on_delete => :cascade
end #unless DB.table_exists? :taggings

class Item < Sequel::Model
  #many_to_one :parent, :class => self
	#plugin :tree
  many_to_one :type
  many_to_many :entries, class: :items 
  many_to_many :history, class: :items 
	
	#one_to_many :directories, :class => self, :key=>:parent_id, :graph_conditions => { :type => Type[:name=>"directory"] }
	
	def directories
		children.select{ |c| c.type == Type[:name=>"directory"] }
	end
	def files
		children.select{ |c| c.type != Type[:name=>"directory"] }
	end
	

  def self.tagged tags
    self.where( tags.map{|t| Sequel.like((t[0]=="#" ? :mimetype : :path), "%"+t.delete("#")+"%") } )
  end
end
class Color < Sequel::Model
  one_to_many :types
end
class Type < Sequel::Model
  one_to_many :items
  many_to_one :color
  many_to_one :default, class: :items #parent, :class => self
end

class DataBase#DBManager
	#TAGS = {}
	#%w{ executable owned }
#  def recurse path, data = {:types => [], :items => []}
  def recurse directory, items = []#, data = {:types => [], :items => []}
  	#directory = Item.find_or_create( :path => path )
    `file -i #{ directory.path.shellescape }/*`.each_line do |line|
      begin
        next if line[/cannot open/]
        type, subtype = line[/:(.*);/][2..-2].split "/"
        type = Type.find_or_create :name => type
        subtype = Type.find_or_create( :name => subtype) \
        	{ |t| t.parent = type }
        
        file = line[/^.*:/][0..-2]
        md5 = nil#Digest::MD5.file( file ).to_s rescue nil
        
        item = Item.new do |i|
        	i.path = file
        	i.md5 = md5
        	i.parent = directory
        	i.type = subtype
        	i.executable = FileTest.executable? file
        end
        #item.tags << @tags[:exectable] if FileTest.executable? file
        if subtype.name == "directory"
	        items = recurse item.save, items
        else
          items << item
        end
        #data[:types] << [type, subtype]
        #recurse file, data if subtype == "directory"
  #      Thread.new{recurse info[0], data} if info[1] == "inode/directory"
      rescue ArgumentError => e 
        DBLOG.error(line+$!.message)
      end
    end
    p directory.path
    items 
  end

  def index path="."
  #  binding.pry
  	if File.directory? path
    	DB.transaction do
				#@tags[:executable] = Tag.find_or_create :name => "executable"
 				path = File.absolute_path(path)
       	root = Item.find_or_create(:path => path) do |i|
      		i.type = Type.find_or_create :name => "directory" 
      	end
      	#p root
      	Item.multi_insert recurse( root )
      		#while Thread.list.count > 1
        #	puts "files: %s\e[1A" % data[:files].count 
        #	sleep 0.2
      	#end
      	#Tag.multi_insert data[:tags].keys.map{|t| Tag.new name: t.to_s, count: data[:tags][t][:count]  }
      	#tags = Tag.all.map{ |t| [t.name.to_sym, t.id] }.to_h
      	#Tagging.multi_insert data[:tags].map{ |tag,list| list[:available].map{ |a| Tagging.new( :supported_id => tags[tag], :available_id => tags[a] ) } }.flatten
  	#      Tag.multi_insert data[:tags].map{ |t,a| Tag.new(:name=>t) 
  		end 
  	end
  end

  def search q
    puts Item.tagged(q.split).select_map(:path).join "\n"
  #  for d in Item.where("path like ?", "%"+q+"%").all.map(&:path)
  #    puts "\e[1;33m%s\e[1;34m%s\e[1;33m%s" % [d.partition(/#{q}/)]
  #  end
  #  for d in Keyword.where(:name=>q.lowercase).join(:occurences, :keyword_id=>:id).join(:documents, :id=>:document_id).order(:count).reverse.all
  #    puts "\e[1;32m %s :\e[1;34m %i \e[0m times" % [d.values[:path],d.values[:count]]

  #  end
  end
  
	#shell tab-completion for tags
  def complete s=""
    DBLOG.info( $*)
    a = $*[1].split[1..-1] #.shift
    a << "" if $*[1][-1] == " "
    puts public_methods(false).join " " if a.count == 1 

    case a.shift
      when "search"
        puts Tag.where(Sequel.like(:name, a[0]+"%")).select_map(:name).join " " if a.count == 1
        puts Tag[name: a[0]].availables_dataset.select_map(:name).join(" ") if a.count == 2 
#        a.map{|a| Tag[name: a].availables_dataset.select_map :name }
      end
  end

  def help command="help"
    puts <<HELP
    Usage: unite [command] [arguments ...]

    commands:
      index [path]  : recursively index files in [path] 
      search [tags ...] : search for files in filenames and mimetypes

HELP
  end
end

#puts eval("%s '%s'" % ARGV) if !ARGV.empty?
#p $0
eval "DataBase.new.%s '%s'" %  [ $*[0], $*[1..-1].join(" ") ] #if $0 == "unite"#unless $*.empty?
#eval "%s '%s'" % ARGV rescue help if ARGV
