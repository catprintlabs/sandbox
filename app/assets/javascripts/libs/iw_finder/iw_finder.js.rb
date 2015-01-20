require 'opal'
require 'promise'
require 'opal-jquery'
require 'template'
require 'browser/delay'

class IWFinder
  
  IW_LOCATION = "http://iw2.catprint.com"
  
  attr_reader :user
  
  def initialize(container, user, html5_enabled)
    @container = container
    @user = user
    @files = {}
    @html5_enabled
    update
  end
  
  def map_state(state)
    @state_map ||= {
      "initialized" => "loading",
      "uploading" => @html5_enabled ? "transferring" : "loading",
      "uploaded" => "processing pages",
      "ready" => "ready",
      "error" => "error"
      }
    @state_map[state] || state
  end
  
  def update
    HTTP.get("#{IW_LOCATION}/JSONPservices.aspx?command=GetFileList&userId=#{@user}&callback=?", dataType: 'json') do |data|
      is_loading = false
      @update_pending.abort if @update_pending
      data.json["files"].reverse.each do |file|
        unless file["trashed"]
          id = file["id"]
          file.delete("percentComplete") if file["iw2State"]=="initialized"
          file["percentComplete"] = ((file["panelCount"].to_f / file["totalPanels"].to_f)*100).round if file["iw2State"]=="uploaded"
          file[:current_state] = map_state(file["iw2State"]) # need to set an instance variable because of bug/limitation in opal erb processing 
          file[:loading] = file["state"]=="loading"
          current_file_data = (@files[id] ||= {})
          puts "iw2state = #{file['iw2State']} @current_state = #{@current_state} @loading = #{@loading} state = #{file['state']} %c = #{file['percentComplete']} %c = #{current_file_data['percentComplete']}"
          current_file_data.merge!(file)
          current_file_data[:updated] = true
          if current_file_data["fileName"] and (match = current_file_data["fileName"].match(/(^.*)(\..{0,5}$|.{5}$)/))
            current_file_data[:filename_head] = match.captures[0]
            current_file_data[:filename_tail] = match.captures[1]
          else
            current_file_data[:filename_head] = current_file_data["fileName"]
            current_file_data[:filename_tail] = ""
          end 
          is_loading ||= file[:loading]
          if current_file_data["state"] == "ready" and !current_file_data[:panels]
            HTTP.get("#{IW_LOCATION}/JSONPservices.aspx?command=GetPanelList&fileId=#{id}&callback=?", dataType: 'json') do |panels|
              current_file_data[:panels] = panels.json["panels"]
              puts "got the panels for #{current_file_data['fileName']}"
              render_pending
            end
          end
        end
      end
      @files.each { |id, value| value.delete(:updated) { @files.delete(id) }}
      @update_pending = after(is_loading ? 2 : 60) { update }
      render
    end
  end

  def files
    cycles = [:odd, :even]
    @files.collect { |id, file| file }.sort { |a, b| b["theDate"] <=> a["theDate"] }.tap do | sorted_files | 
      sorted_files.each do |file|
        cycles.push (file[:cycle] = cycles.shift)
      end
    end
  end

  def progress_for(secure_id, percent_complete)
    @files[secure_id].merge!({"percentComplete" => percent_complete})
    render_pending
  end

  def delete(file)
    @files.delete(file["id"])
    HTTP.get("#{IW_LOCATION}/v1/files/#{file["id"]}/trash?callback=?", dataType: 'json')
    render
  end
  
  def render
    if @rendering_paused
      @rendering_in_queue = true
      return
    end
    @rendering_in_queue = false
    @render_pending.abort and @render_pending = nil if @render_pending
    @container.html = Template[__FILE__.gsub(/iw_finder$/,"template")].render(self)
    Element['.iw-finder-opener input'].on :click do |evt|
      file = @files[Element[evt.current_target].attr('file-id')]
      file[:show_panels] = !file[:show_panels]
      render
      resume_rendering
    end
    Element['.iw-finder-delete input'].on :click do |evt|
      file = @files[Element[evt.current_target].attr('file-id')]
      if ["confirm", "cancel"].include? Element[evt.current_target].value
        delete file
        resume_rendering
      else
        Element[evt.current_target].value = "confirm"
        pause_rendering_for(5) { Element[evt.current_target].value = "delete" }
      end
    end
  end  
  
  def render_pending
    @render_pending ||= after(1) { render }
  end

  def pause_rendering_for(seconds)
    @rendering_paused = true
    after(seconds) do
      resume_rendering
      yield
    end
  end

  def resume_rendering
    @rendering_paused = false
    render if @rendering_in_queue
  end
  
end
    