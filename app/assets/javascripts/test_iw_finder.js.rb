require 'opal'
require 'promise'
require 'opal-jquery'

def create_uploader finder
  UploadWidget.new(Element['#rb_form_here'], finder.user) do |upload|
    upload.create   { puts "(ruby) uploader created #{upload.parent.attr('id')} #{upload.status}" }
    upload.submit do  
      finder.update
      create_uploader finder
    end
    upload.progress do 
      percent_complete = (upload.progress[:percent_complete] || 0)*100.round
      finder.progress_for upload.progress[:secure_token], percent_complete, upload.progress[:name]
    end
  end
end

class Element
  expose :dotdotdot
end

Document.ready? do 
  
  Element['.iw-finder-filename div'].dotdotdot({wrap: 'letter', fallbackToLetter: true, after: '.iw-finder-filename-extension', watch: true}.to_n)
  puts 'did dotdotdot i think'
  create_uploader IWFinder.new(Element["#iw_finder_here"], "mastertesterfromouterspace", true)

end
