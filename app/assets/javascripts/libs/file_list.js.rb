require 'opal'

class FileList < Array
  
  # wraps native HTML5 filelist object
  
  def initialize(*native_file_inputs)
    native_file_inputs.each do |native_file_input|
      `Array.prototype.slice.call(#{native_file_input})`.each { |native_file| self << FileList::FileInput.new(native_file) }
    end
  end
  
  class FileInput

    # wraps native HTML5 file object
    
    def initialize(native_file)
      @file = native_file
    end

    def to_n
      `self.file`
    end
    
    def name
      `self.file.name`
    end
    
  end
  
end  

class Element 
  
  def files
    FileList.new *self.collect { |fileinput|
      `#{fileinput}[0].files` 
      }
  end 
  
end