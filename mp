#!/usr/bin/ruby
#$LOAD_PATH << "#{File.dirname __FILE__}/."
require './data/manual.rb'
 
eval "ManPage.new('%s').%s '%s'" %  [ $*[0], $*[1], $*[2..-1].join(" ") ] if __FILE__ == $0


