# Create a web dialog.
class WebUI
  
  # Relative location of the Cutlister input html page.
  @@ui_location = '/ui.html'
  
  # Make the active model a class variable.
  # @@model = Sketchup.active_model
  
  puts "[WebUI] @@ui_location: #{@@ui_location}" if $cutlister_debug
  # puts "@@result_location: #{@@result_location}" if $cutlister_debug
  # puts "[WebUI] @@model: #{@@model}" if $cutlister_debug
  
  # Gets the location of the UI HTML file.
  def get_ui_location
    
    @@ui_location 
    
  end
  
  # Create a page title to use for the page title.
  def page_title
    
    page_title = "Cutlister (#{$version})"#  - Cutlist for project: #{@@model.title}
    
    puts "[WebUI.page_title] page_title: #{page_title}" if $cutlister_debug
    
    return page_title
    
  end

  def open_dialog

    @dialog = UI::WebDialog.new(page_title, true, @pref_key, @width, @height, @left, @top)
    
    puts "[WebUI.open_dialog] @dialog: #{@dialog}" if $cutlister_debug
    
    @dialog.set_file(File.dirname(__FILE__) + get_ui_location)

  end
  
  def add_callbacks
  end

  # Display the WebDialog.
  def display
  
    puts "[WebUI.dispaly] Showing WebUI dialog..." if $cutlister_debug
  
    @dialog.show {}
  
  end
  
  # This method creates and opens the web dialog.
  def show(results="")
    
    @results = results
    
    # puts "[WebUI.show] @results: #{@results}" if $cutlister_debug
    
    open_dialog
    
    puts "[WebUI.show] Adding handle_close action callback..." if $cutlister_debug
    
    # Create a callback that handles closing the dialog if the close button 
    # was clicked.
    @dialog.add_action_callback("handle_close") { |dialog, params| 
      
      puts "[WebUI.show] Closing web dialog..." if $cutlister_debug
      
      @dialog.close()
      
    }
    
    add_callbacks
    display
    
    return nil
    
  end
  
end


# The WebDialog UI for choosing options for the cut list.
class ToolWebUI < WebUI
  
  def initialize
    
    # Set up the UI options.
    # @model = Sketchup.active_model
    # @selection = @model.selection
    @pref_key = "CutlisterUI"
    @width = 600
    @height = 640
    @left = 100
    @top = 100
    @formats = get_format_list
    @list_types = get_list_types
    
    # puts "[ToolWebUI.initialize] @model: #{@model}" if $cutlister_debug
    # puts "[ToolWebUI.initialize] @selection: #{@selection}" if $cutlister_debug
    if $cutlister_debug
      puts "[ToolWebUI.initialize] @pref_key: #{@pref_key}"
      puts "[ToolWebUI.initialize] @width: #{@width}"
      puts "[ToolWebUI.initialize] @height: #{@height}"
      puts "[ToolWebUI.initialize] @left: #{@left}"
      puts "[ToolWebUI.initialize] @top: #{@top}"
      puts "[ToolWebUI.initialize] @formats: #{@foramts}"
      puts "[ToolWebUI.initialize] @list_types: #{@list_types}\n\n"
    end
  
  end
  
  # Grabs a list of all the subclasses of the OuputFormat class to display in the 
  # WebDialog "Formats" select box.
  def get_format_list
    
    @format_subclasses = Renderer.subclasses.reverse
    
    puts "[ToolWebUI.get_format_list] @format_subclasses: #{@format_subclasses}\n" if $cutlister_debug
    
    subclass_list = []
    
    # Add each subclass's properties to the array.
    @format_subclasses.each { |s| 
      
      # Check to see if there is a display_name for the sub-class. 
      # If there isn't one than we don't show it in the list because we 
      # assume it is a superclass for another class. 
      if s.display_name != nil
        
        subclass_list << ["#{s}", "#{s.display_name}"]
      
      else
        
        puts "Renderer class skipped because it had no `display_name` instance variable..." if $cutlister_debug
      
      end
      
    }
    
    puts subclass_list if $cutlister_debug
    
    return subclass_list
    
  end
  
  # Grabs a list of all the subclasses of the Cutlist class to display in the 
  # WebDialog "List Types" select box.
  def get_list_types
    
    @cutlist_subclasses = Cutlist.subclasses.reverse
    
    puts "[ToolWebUI.get_list_types] @cutlist_subclasses: #{@cutlist_subclasses}\n\n" if $cutlister_debug
    
    subclass_list = []
    
    # Add each subclass's properties to the array.
    @cutlist_subclasses.each { |s| 
      
      # Check to see if there is a display_name for the sub-class. 
      # If there isn't one than we don't show it in the list because we 
      # assume it is a superclass for another class.
      if s.display_name != nil
      
        subclass_list << ["#{s}", "#{s.display_name}"]
      
      else
      
        puts "Cutlist class skipped because it had no `display_name` instance variable...\n\n" if $cutlister_debug
      
      end
    
    }
    
    puts subclass_list if $cutlister_debug
    
    return subclass_list
    
  end
  
  # Add callbacks for the WebDialog to handle the running of the JavaScript 
  # function that runs the Cutlister plugin from the UI.
  def add_callbacks

    puts "[ToolWebUI.add_callbacks] Adding handle_run action callback...\n\n" if $cutlister_debug
    
    @dialog.add_action_callback("handle_run") { |dialog, params|
      
      puts "[ToolWebUI.add_callbacks('handle_run')] handle_run called:\ndialog: #{dialog}\nparams: #{params}\n\n" if $cutlister_debug
      
      model = Sketchup.active_model
      selection = model.selection
      
      puts "[ToolWebUI.add_callbacks('handle_run')] model: #{model}" if $cutlister_debug
      puts "[ToolWebUI.add_callbacks('handle_run')] selection: #{selection}" if $cutlister_debug
      
      results = params.split('&') # Split params by ampersands, which is how jQuery serializes form data.
      # results = results
      
      # puts "[ToolWebUI.add_callbacks('handle_run')] results: #{results}\n\n"
      
      # Create a new hash to add our form results to.
      result_hash = Hash.new
      
      # Loop through each result to construct the key/value pairs of parameters.
      results.each { |r|
        
        # Split each item in the results array and create a new array.
        param = r.split('=')
        
        # Construct the key/value pair for the result_hash.
        key = param[0]
        value = param[1] ? param[1].split(%r{,\s*}) : nil
        
        # If there is a value, split it up.
        if value
          
          value.each { |v| 
            
            v.sub!(/^\+*|\+*$/, '') # Remove the leading and trailing `+` characters.
            v.tr!('+', ' ') # Replace the `+` characters with spaces.
            
          }
          
        end
        
        # Debug the key/value pairs...
        puts "[ToolWebUI.add_callbacks('handle_run')] results key: #{key}" if $cutlister_debug
        if value
          value.each { |v| puts "[ToolWebUI.add_callbacks('handle_run')] results value (array): #{v}" if $cutlister_debug }
        end
        puts "\n" if $cutlister_debug
        
        # Add the key/value pair to the result_hash.
        result_hash[key] = value
        
      }
      
      # Add debugging info...
      if $cutlister_debug
        puts "[ToolWebUI.add_callbacks('handle_run')] result_hash['format']: #{result_hash['format']}" 
        puts "[ToolWebUI.add_callbacks('handle_run')] result_hash['list_type']: #{result_hash['list_type']}"
        puts "[ToolWebUI.add_callbacks('handle_run')] result_hash['sheets']: #{result_hash['sheets']}"
        puts "[ToolWebUI.add_callbacks('handle_run')] result_hash['solids']: #{result_hash['solids']}"
        puts "[ToolWebUI.add_callbacks('handle_run')] result_hash['hardware']: #{result_hash['hardware']}"
        puts "[ToolWebUI.add_callbacks('handle_run')] result_hash['sheet_materials']: #{result_hash['sheet_materials']}"
        puts "[ToolWebUI.add_callbacks('handle_run')] result_hash['solid_materials']: #{result_hash['solid_materials']}"
        puts "[ToolWebUI.add_callbacks('handle_run')] result_hash['round_dimensions']: #{result_hash['round_dimensions']}"
      end
      
      # Construct the options hash.
      options = {
        "show_sheets" => result_hash['sheets'].to_s == "on" ? true : false,
        "show_solids" => result_hash['solids'].to_s == "on" ? true : false,
        "show_hardware" => result_hash['hardware'].to_s == "on" ? true : false,
        "sheet_materials" => result_hash['sheet_materials'] != nil ? result_hash['sheet_materials'].to_a : nil,
        "solid_materials" => result_hash['solid_materials'] != nil ? result_hash['solid_materials'].to_a : nil,
        "round_dimensions" => result_hash['round_dimensions'].to_s == "on" ? true : false,
      }
      
      puts "[ToolWebUI.add_callbacks('handle_run')] options: #{options.inspect}" if $cutlister_debug
      
      # Get all the parts in the selection.
      parts = PartList.new(model, selection, options)
      
      puts "[ToolWebUI.add_callbacks('handle_run')] parts: #{parts}" if $cutlister_debug
      
      # Construct a Renderer instance based on what was chosen in the UI.
      # 
      # This takes the name of a class and creates a new instance of it.
      format_string = result_hash['format'].to_s
      renderer = Kernel.const_get(format_string).new(result_hash['round_dimensions'].to_s == "on" ? true : false)
      
      puts "[ToolWebUI.add_callbacks('handle_run')] renderer: #{renderer}" if $cutlister_debug
      
      # Construct a Cutlist instance based on what was chosen in the UI.
      # 
      # This takes the name of a class and creates a new instance of it.
      list_type_string = result_hash['list_type'].to_s
      cutlist = Kernel.const_get(list_type_string).new(model, renderer, parts, options).build
      
      # puts "[ToolWebUI.add_callbacks('handle_run')] cutlist: #{cutlist}\n\n" if $cutlister_debug
      
      # Render cutlist.
      renderer.render(model, cutlist)
    
    }

  end

  # Display the WebDialog.
  def display

    @dialog.show {
      
      puts "[ToolWebUI.display] Showing GUI dialog." if $cutlister_debug
      
      # Run a script to populate the "Formats" select box in the WebDialog.
      # @dialog.execute_script("populate_format_list(#{@formats});")
      @dialog.execute_script("$('#id_format').populate_select({ items: #{@formats.inspect} });")

      # Run a script to populate the "List Types" select box in the WebDialog.
      # @dialog.execute_script("populate_list_types(#{@list_types});")
      @dialog.execute_script("$('#id_list_type').populate_select({ items: #{@list_types.inspect} });")
      
    }

  end
  
end


# The ResultGUI displays the results of a cut list when the "Web Page" format 
# is chosen in the ToolWebUI.
class ResultsWebUI < WebUI
  
  def initialize
    
    # Set up the UI options.
    @pref_key = "CutlisterResults"
    @width = 700
    @height = 600
    @left = 100
    @top = 100

    if $cutlister_debug
      puts "[ResultsWebUI.initialize] @pref_key: #{@pref_key}"
      puts "[ResultsWebUI.initialize] @width: #{@width}"
      puts "[ResultsWebUI.initialize] @height: #{@height}"
      puts "[ResultsWebUI.initialize] @left: #{@left}"
      puts "[ResultsWebUI.initialize] @top: #{@top}\n\n"
    end
  
  end
  
  def open_dialog

    @dialog = UI::WebDialog.new(page_title, true, @pref_key, @width, @height, @left, @top)
    
    puts "[ResultsWebUI.open_dialog] @dialog: #{@dialog}\n\n" if $cutlister_debug
    
    @dialog.set_html(@results)

  end
  
  # Send the results to the page so they can be outputted.
  def display
    
    @dialog.show {
      
      puts "[ResultsWebUI.display] Showing ResultsWebUI...\n\n" if $cutlister_debug
      
    }
    
  end
  
end

