require "minitest/autorun"
require "minitest/pride"
require_relative "../o.rb"

here = "#{File.dirname __FILE__}"
stack = here + "/stack"


describe Writer do
	
	before do
		stack.rm if stack.exists?
		$stack = Writer.new file: stack
		@data = Directory.new(here + "/data")
		$stack << @data		
	end
	
	describe "<<" do
		it "must contain only the data directory" do

			$stack.content.must_equal [@data]
		end
		it "must match content with the file it mirrors" do
			
			$stack.content.to_yaml.must_equal stack.read
		end
	end
	
	describe ".action" do
	#context "clicking on the first entry" do
		it "must add the entry to the stack" do
			$stack.action
			$world.last.action
			$stack.content.first.to_s.must_equal "link"
		end
		
		it "must add a new writer containing the files in data" do
			#halt
			$stack.action
			$world.last.content[0].to_s.must_equal "link"
			$world.last.content[1].to_s.must_equal "text.rb"
			$world.last.content[2].to_s.must_equal "xmas.mp4"
		end	
		
		#it "
			
	end
end
