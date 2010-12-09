# Create a web dialog.
class WebUI
  
  # def initialize #(model)
  #   
  #   
  #   
  # end
  
  # Relative location of the Cutlister input html page.
  @@ui_location = '/ui.html'
  
  # Make the active model a class variable.
  @@model = Sketchup.active_model
  
  puts "@@ui_location: #{@@ui_location}" if $debug
  # puts "@@result_location: #{@@result_location}" if $debug
  puts "@@model: #{@@model}" if $debug
  
  # Gets the location of the UI HTML file.
  def get_ui_location
    
    @@ui_location 
    
  end
  
  # Create a page title to use for the page title.
  def page_title
    
    page_title =  "Cutlister (#{$version}) - Cutlist for project: "# + @@model.title
    
    puts "page_title: #{page_title}" if $debug
    
    return page_title
    
  end

  def open_dialog

    @dialog = UI::WebDialog.new(page_title, true, @pref_key, @width, @height, @left, @top)
    
    puts "@dialog: #{@dialog}" if $debug
    
    @dialog.set_file(File.dirname(__FILE__) + get_ui_location)

  end
  
  def add_callbacks
  end

  # Display the WebDialog.
  def display
  
    puts "Showing WebUI dialog..." if $debug
  
    @dialog.show {}
  
  end
  
  # This method creates and opens the web dialog.
  def show(results="")
    
    @results = results
    
    puts "@results: #{@results}" if $debug
    
    open_dialog
    
    puts "Adding handle_close action callback..." if $debug
    
    # Create a callback that handles closing the dialog if the close button 
    # was clicked.
    @dialog.add_action_callback("handle_close") { |dialog, params| 
      
      puts "Closing web dialog..."
      
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
    @model = Sketchup.active_model
    @selection = @model.selection
    @pref_key = "CutlisterUI"
    @width = 500
    @height = 490
    @left = 100
    @top = 100
    @formats = get_format_list
    @list_types = get_list_types
  
    puts "ToolWebUI options: pref_key #{@pref_key}, width #{@width}, height #{@height}, left #{@left}, top #{@top}\n" if $debug
    puts "@formats: #{@formats}" if $debug
    puts "@list_types: #{@list_types}\n" if $debug
  
  end
  
  # Grabs a list of all the subclasses of the OuputFormat class to display in the 
  # WebDialog "Formats" select box.
  def get_format_list
    
    @format_subclasses = Renderer.subclasses.reverse
    
    puts "@format_subclasses: #{@format_subclasses}\n" if $debug
    
    subclass_list = []
    
    # Add each subclass's properties to the array.
    @format_subclasses.each { |s| 
      
      # Check to see if there is a display_name for the sub-class. 
      # If there isn't one than we don't show it in the list because we 
      # assume it is a superclass for another class. 
      if s.display_name != nil
        
        subclass_list << "{ 'name' : '#{s}',  'display_name' : '#{s.display_name}'}" 
      
      else
        
        puts "Renderer class skipped because it had no `display_name` instance variable..." if $debug
      
      end
      
    }
    
    puts subclass_list if $debug
    
    return "[" + subclass_list.join(',') + "]"
    
  end
  
  # Grabs a list of all the subclasses of the Cutlist class to display in the 
  # WebDialog "List Types" select box.
  def get_list_types
    
    @cutlist_subclasses = Cutlist.subclasses.reverse
    
    puts "@cutlist_subclasses: #{@cutlist_subclasses}\n\n" if $debug
    
    subclass_list = []
    
    # Add each subclass's properties to the array.
    @cutlist_subclasses.each { |s| 
      
      # Check to see if there is a display_name for the sub-class. 
      # If there isn't one than we don't show it in the list because we 
      # assume it is a superclass for another class.
      if s.display_name != nil
      
        subclass_list << "{ 'name' : '#{s}',  'display_name' : '#{s.display_name}'}" 
      
      else
      
        puts "Cutlist class skipped because it had no `display_name` instance variable...\n\n" if $debug
      
      end
    
    }
    
    puts subclass_list if $debug
    
    return "[" + subclass_list.join(',') + "]"
    
  end
  
  # Add callbacks for the WebDialog to handle the running of the JavaScript 
  # function that runs the Cutlister plugin from the UI.
  def add_callbacks

    puts "Adding handle_run action callback...\n\n" if $debug
    
    @dialog.add_action_callback("handle_run") { |dialog, params|
      
      puts "handle_run has been called from within the WebDialog:\ndialog=#{dialog}\nparams=#{params}\n\n" if $debug
      
      results = params.split('&') # Split params by ampersands, which is how jQuery serializes form data.
      # results = results
      
      puts "Results: #{results}\n\n"
      
      # Create a new hash to add our form results to.
      result_hash = Hash.new
      
      # Loop through each result to construct the key/value pairs of parameters.
      results.each { |r|
        
        # Split each item in the results array and create a new array.
        param = r.split('=')
        
        # Construct the key/value pair for the result_hash.
        key = param[0]
        value = param[1].split(%r{,\s*})
        value.each { |v| 
          
          v.sub!(/^\+*|\+*$/, '') # Remove the leading and trailing `+` characters.
          v.tr!('+', ' ') # Replace the `+` characters with spaces.
          
        } 
        
        # Debug the key/value pairs...
        puts "Key: #{key}" if $debug
        value.each { |v| puts "Value: #{v}" if $debug }
        puts "\n" if $debug
        
        # Add the key/value pair to the result_hash.
        result_hash[key] = value
        
        
      }
      
      # Add debugging info...
      puts "format: #{result_hash['format']}" if $debug
      puts "list_type: #{result_hash['list_type']}" if $debug
      puts "show_sheets: #{result_hash['sheets']}" if $debug
      puts "show_solids: #{result_hash['solids']}" if $debug
      puts "show_hardware: #{result_hash['hardware']}" if $debug
      puts "sheet_materials: #{result_hash['sheet_materials']}" if $debug
      puts "solid_materials: #{result_hash['solid_materials']}\n\n" if $debug
      
      # Construct the options hash.
      options = {
        "show_sheets" => result_hash['sheets'].to_s == "on" ? true : false,
        "show_solids" => result_hash['solids'].to_s == "on" ? true : false,
        "show_hardware" => result_hash['hardware'].to_s == "on" ? true : false,
      }
      
      puts "options hash: #{options.to_s}\n\n" if $debug
      
      # Get all the parts in the selection.
      parts = PartList.new(@model, @selection)
      
      puts "parts: #{parts}" if $debug
      
      # Construct a Renderer instance based on what was chosen in the UI.
      # 
      # This takes the name of a class and creates a new instance of it.
      format_string = result_hash['format'].to_s
      renderer = Kernel.const_get(format_string).new()
      
      puts "renderer: #{renderer}" if $debug
      
      # Construct a Cutlist instance based on what was chosen in the UI.
      # 
      # This takes the name of a class and creates a new instance of it.
      list_type_string = result_hash['list_type'].to_s
      cutlist = Kernel.const_get(list_type_string).new(@model, renderer, parts, options).build
      
      puts "cutlist: #{cutlist}\n\n" if $debug
      
      # Render cutlist.
      renderer.render(@model, cutlist)
    
    }

  end

  # Display the WebDialog.
  def display

    @dialog.show {
      
      puts "Showing GUI dialog." if $debug
      
      # Run a script to populate the "Formats" select box in the WebDialog.
      @dialog.execute_script("populate_format_list(#{@formats});")

      # Run a script to populate the "List Types" select box in the WebDialog.
      @dialog.execute_script("populate_list_types(#{@list_types});")
      
    }

  end
  
end


# The ResultGUI displays the results of a cut list when the "Web Page" format 
# is chosen in the ToolWebUI.
class ResultsWebUI < WebUI
  
  def initialize

    # super(model)
    
    # Set up the UI options.
    @pref_key = "CutlisterResults"
    @width = 700
    @height = 600
    @left = 100
    @top = 100
  
    puts "ResultsWebUI options: pref_key #{@pref_key}, width #{@width}, height #{@height}, left #{@left}, top #{@top}" if $debug
  
  end
  
  def add_callbacks
    
    puts "results: #{@results}" if $debug
    
  end
  
  def open_dialog

    @dialog = UI::WebDialog.new(page_title, true, @pref_key, @width, @height, @left, @top)
    
    puts "@dialog: #{@dialog}" if $debug
    
    # @dialog.set_file(File.dirname(__FILE__) + get_result_location)
    @dialog.set_html(@results)

  end
  
  # Send the results to the page so they can be outputted.
  def display
    
    @dialog.show {
      
      puts "Showing ResultsWebUI..." if $debug
      
      # @dialog.execute_script("handleResults(\'#{@results}\');");
      
    }
    
  end
  
end

