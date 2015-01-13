require 'opal'
require 'promise'
require 'opal-jquery'

def create_uploader 
  UploadWidget.new(Element['#rb_form_here'], "me@benhughes.name", multiple: true) do |upload|
    upload.create   { puts "(ruby) uploader created #{upload.parent.attr('id')} #{upload.status}" }
    upload.submit do 
      puts "(ruby) file upload submitted"; 
      create_uploader 
    end
    upload.progress do 
      puts [
        "(ruby) progress is being made on #{upload.progress[:name]}",
        "secure token: #{upload.progress[:secure_token]}", 
        "percent loaded: #{upload.progress[:percent_complete]*100.round}"
      ].join(" -  ")
    end
  end
end

Document.ready? do 
  puts "adding a ruby uploader!"
  create_uploader
  UploadWidget.new(Element['rb_form_here'], "me@benhughes.name", http_link: "#{`window.location.host`}/catprintqrcode.com") do |upload|
    upload.submit { puts '(ruby) http submitted!' };
    upload.progress { puts "(ruby) http progress on #{upload.progress[:name]}" }
  end
end