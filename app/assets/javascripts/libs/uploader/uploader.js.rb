require 'opal'
require 'promise'
require 'opal-jquery'
require 'template'

class Element # pre jquery 1.7 does not have "on", so we have to create explicit methods for each event handler

  def change(&block) 
    Document.ready? do 
      `jQuery(#{self}).change(#{block})`
    end
  end
  
  expose :submit
  
end

class UploadWidget
  
  attr_reader :status
  attr_reader :form
  attr_reader :parent
  
  def progress(&block) 
    # progress can be called to get the progress OR as part of the dsl
    yield self if block
    @_progress || {}
  end
  
  # example: 
  
  # UploadWidget.new(parent, user, opts = {}, &block)
  # Creates a new uploader input box, and handler.
  #   parent is jquery Element that the widget will be appended to
  #   user is the iw user that the uploads will be associated with
  #   available options
  #     http_link: remote_url to fetch file from (default nil) indicates to upload will be from a remote url
  #     multiple: true (default false) indicates that html5 multiple file uploads are allowed
  #   block will be called with each upload event and be passed the upload widget instance
  #
  #   you can access the status (a hash with keys :status, :name, :secure_token, and :percent_complete.)
  #   and the form (a jquery element)
  #   you can use helpers create, submit, progress, complete, error to control processing for example
  
  #   UploadWidget.new(parent, user) do |f|
  #     f.create do 
  #       #... do what you need when the widget is created i.e.
  #       Element.form.add_class('my-styles')
  #     end
  #     f.submit do
  #       #... update your UI when the user submits an upload
  #     end
  #     f.progress do
  #       #... update UI when upload progress has been made (only is called for HTML5 upload elements)
  #     end
  #   end
  #
  #   If HTML5 is available the block will be called as the upload progresses.  If multiple is true, then 
  #   multiple calls will be made for each file in the collection, each file will have a unique secure_token
  #   which can be used to track which UI element to update
  #
  #   You can also create an UploadWidget from jQuery.
  #   $(selector).uploader({...opts...}) which will add an uploader widget to every element selected.
  #   each option is http_link, multiple, or a function named create, submit, progress, complete or error which will be called on that status
  #   and passed the uploader instance.  For example:
  #
  #  $('#some-div').uploader({multiple: true, create: function(f) {f.form.addClass('my-style')}})
  
  def initialize(parent, user, opts = {}, &block)
    opts = {html5: :multiple}.merge opts
    @parent = parent
    @user = user
    @block = block
    @id = "_upload_widget_#{self.object_id}"
    @status = :create
    http_link = opts[:http_link] 
    if http_link
      http_link = http_link.strip
      http_link = "http://#{http_link}" unless http_link =~ /^htt(ps|p):\/\//
    end
    @http_link = http_link
    @html5_enabled = opts[:html5] and `window['File']`
    @multiple = (opts[:html5] == :multiple)
    @parent.append(Template[__FILE__.gsub(/uploader$/,"form")].render(self))
    @form = Element["##{@id}_form"]
    @form.change("##{@id}_form") { handle_form_change } 
    @block.call self
    handle_form_change if @http_link 
  end
  
  def new_iw_file
    HTTP.get("#{IWFinder::IW_LOCATION}/v1/files/new?user=#{@user}&callback=?", dataType: 'json') do |data|
      if data.json["errormessage"]
        @status = :error
        @error_message = data.json["errormessage"]
        @block.call self
      else
        yield data.json["secure_token"], data.json["upload_url"]
      end
    end
  end
  
  def handle_form_change  
    i_frame = Template[__FILE__.gsub(/uploader$/,"iframe")].render(self)
    @parent.append(i_frame)
    @form.toggle_class('_upload_widget_form_class') 
    if @html5_enabled and !@http_link
      @form.find('input[type=file]').files.each do |file|
        new_iw_file do |secure_token, upload_url| 
          xhr = lambda { build_xhr_progress_handler({status: :uploading, name: file.name, percent_complete: 0, secure_token: secure_token}) }
          HTTP.put(upload_url, data: file, cache: false, contentType: false, processData: false, xhr: xhr) do |response|
            if response.ok?
              HTTP.get("#{IWFinder::IW_LOCATION}/v1/files/upload_complete?secure_token=#{secure_token}&file_name=#{file.name}&callback=?", dataType: 'json')
            else
              puts 'HTTP put failed'
            end
          end
        end
      end
    else
      new_iw_file do |secure_token|
        @form.attr("action", "#{IWFinder::IW_LOCATION}/v1/files?X-Progress-ID=#{secure_token}")
        @form.find('[name=secure_token]').value = secure_token
        @_progress = {status: :uploading, name: @http_link ? @http_link : @form.find('file').value, percent_complete: 0, secure_token: secure_token}
        @progress = @_progress.to_n
        @form.submit
        @status = :progress
        @block.call self
      end
    end
    @status = :submit
    @block.call self
    @form.hide
  end
  
  def build_xhr_progress_handler(progress)
    xhr = `new window.XMLHttpRequest()`
    update_progress = lambda do |evt|
      progress[:percent_complete] = `evt.loaded / evt.total` if `evt.lengthComputable`
      @status = :progress
      @_progress = progress
      @progress = @_progress.to_n
      @block.call self
    end
    `xhr.upload.addEventListener("progress", update_progress, false)`
    xhr
  end
  
  # provides a simple ruby dsl
    
  [:create, :submit, :complete, :error].each do |status|
    define_method status do |&block|
      block.call if status==@status
    end
  end
  
  # provides a jquery interface
  
  Element.extend :uploader do |tthis, opts|
    #puts "opts['multiple'] = #{`opts['multiple']`} and !! = #{`!!opts['multiple']`}
    UploadWidget.new(tthis, `#{opts}['user']`, http_link: `!#{opts}['http_link']` ? nil : `#{opts}['http_link']`, multiple: `!!#{opts}['multiple']`) do |f|
      `#{opts}[#{f.status}].apply(#{tthis}, [#{f}])` if `!!#{opts}[#{f.status}]`
    end 
  end 
  
end
