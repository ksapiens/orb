#!/usr/bin/ruby
#$LOAD_PATH << "#{File.dirname __FILE__}/lib/"

#require 'rubygems'
require 'sequel'
#require 'logger'
#require 'shellwords'
#require 'digest/md5.so'
#require 'profile'
#THREADS = 4


#DB.loggers << Logger.new("tagger.log")
#DBLOG = Logger.new("db.log")

#DB.create_table( :types ) do #identity meaning 
#  String :name, :primary_key => true 
  #primary_key :id
 
#  foreign_key :item_id, :items
#  String :shape
#  Char :symbol
  #Integer :count
#end #unless DB.table_exists? :types

#DB.create_table( :colors ) do 
#  primary_key :id
  #foreign_key :field_id
  #String :name
#  Integer :red
#  Integer :green
#  Integer :blue  
#end #unless DB.table_exists? :

DB.create_table( :items ) do #string object word 
  primary_key :id
	#foreign_key :identity_id#, :types
  Integer :type_id
  String :long#, :unique => true 
  String :short
  String :extra
  Integer :color #_id, :colors
  #String :md5, :size => 32 
  #String :found_in #file
  #Integer :position
  #Integer :size
  TrueClass :executable
  DateTime :created_at
  DateTime :updated_at
  
end #unless DB.table_exists? :items
 
DB.create_table( :relations ) do
  primary_key :id
  foreign_key :first_id, :items#, :on_delete => :cascade
  foreign_key :second_id, :items#, :on_delete => :cascade
end 

#DB.create_table( :history ) do
#  primary_key :id
#  foreign_key :type_id, :types#, :on_delete => :cascade
#  foreign_key :item_id, :items#, :on_delete => :cascade
#end 

#class Color < Sequel::Model
#  one_to_many :types#identity
#end

#class Type < Sequel::Model
#  unrestrict_primary_key
#  one_to_many :items
#  many_to_one :color
#  many_to_many :history, join_table: :history
#  many_to_one :default, key: :item_id, class: :items 

#end

#F = 1000
#H = 764
#H = 618
#M = 382
#L = 382
#L= 236
#VL = 146

#BACKGROUND = Color.create red: VL, green: VL, blue: VL
#RED = Color.create red: H, green: L, blue: L
#ORANGE = Color.create red: H, green: M, blue: L
#YELLOW = Color.create	red: H, green: H, blue: L
#GREEN = Color.create red: L, green: H, blue: L
#CYAN = Color.create	red: L, green: H, blue: H
#BLUE = Color.create	red: L, green: L, blue: H
#MAGENTA = Color.create red: H, green: L, blue: H
#3DARK = Color.create	red: M, green: M, blue: M
#BRIGHT = Color.create	red: H, green: H, blue: H
#WHITE = Color.create red: F, green: F, blue: F
