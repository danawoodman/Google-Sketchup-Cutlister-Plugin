

# The OutputFormat class allows exporting cut list data to different file types.
# 
# The main OutputFormat class offers a base class to sub-class in order to add 
# new file types and formats to Cutlister.
# 
# These ouput formats are displayed in the UI when a user chooses a "Format" 
# and are dynamically generated in that list. Meaning, if you sub-class 
# OutputFormat anywhere (within this file or in your own file), it will 
# be automatically added to the drop-down list of formats in the UI.
# 
# This makes it easy to create a new output format and have it show up in the 
# UI without doing any modification to the UI.
class OutputFormat
  
  def initialize(model, data)
    
    @model = model
    @model_name = @model.title
    @data = data
    
    model_path = @model.path
    
    puts "[OutputFormat.initialize] Model path: #{model_path}" if CUTLISTER_DEBUG
    
    if model_path == ""
      
      # TODO: Have this notify the user via the UI instead of a pop-up
      UI.beep
      UI.messagebox("You must save your file before creating a cut list of it!\nNo cut list was generated.")
      
      return nil
      
    end
   
    # Now get the actually directory from the path, so we can put our files 
    # in the same directory.
    @model_path = File.dirname(model_path)
    
  end

  # # Add a display name property for displaying in the web dialog UI.
  # def self.display_name
  # 
  #   @display_name
  # 
  # end
  # 
  # # Add a description property for displaying in the web dialog UI.
  # def self.description
  # 
  #   @description
  # 
  # end
  
  # Open (e.g. create) any files needed for the ouput format.
  def open_files
  end
  
  # # Open the appropriate renderer for the content.
  # def open_renderer
  # end
  
  # Close (e.g. save) all open files.
  def close_files
  end
  
  # Display the results of the output operation.
  # 
  # For files this could mean opening them or displaying a success status to 
  # the user. For formats like HTML this could mean opening a web browser.
  def display_results
  end
  
  # def render
  # end
  
  def write_data(data)
  end
  
  def close
    
    close_files()
    display_results()
    
  end
  
  # Steps required to produce the requested output.
  # 
  # All methods are internal and are called in order. This helps to automate 
  # the outputting of content.
  def run(data = @data)
    
    open_files()
    # open_renderer()
    write_data(data)
    # render()
    close()
    
  end
  
end


# A base class for all file based output formats.
# 
# This makes creating new output formats for file based content a little easier.
# By sub-classing this class rather than the super-class OutputFormat, you 
# gain a few nicities like file naming and result displays.
# 
# This is not meant to be used alone as an output format. Since it does not 
# have a `@display_name` or `@description` class variable it will not show up in 
# the list of format types in the UI.
class FileOutputFormat < OutputFormat

  def initialize(model, data, suffix="cutlist.txt")
    
    super(model, data)
    
    @file_suffix = suffix
    
  end

  def open_files
    
    @full_file_name = "#{@model_path}/#{@model_name}_#{@file_suffix}"
    
    puts "[FileOutputFormat.open_files] Opening file: #{@full_file_name}" if CUTLISTER_DEBUG
    
    @file = File.new(@full_file_name, "w")
    
  end
  
  def write_data(data)
    
    @file.puts data
    
  end

  def close_files
    
    puts "[FileOutputFormat.close_files] Closing files..." if CUTLISTER_DEBUG
    
    @file.close
    
  end
  
  def display_results
    
    puts "[FileOutputFormat.display_results] Displaying results..." if CUTLISTER_DEBUG
    
    # TODO: Have an alert in the UI letting them know it was a success. Would 
    # be nice to also have the the file be linked to or auto opened...
    UI.messagebox "File outputted to:\n#{@full_file_name}", MB_OK
    
  end

end


# Output a CSV file for importing into programs like Microsoft Excel (Windows) 
# and iWork Numbers (Mac) as well as any other program that can read CSV files.
# 
# CSV stands for Comma-Seperated Values. This means that each cut list part 
# will be written to the file on it's own line, with each property separated 
# by commas.
class CSVOutputFormat < FileOutputFormat

  def initialize(model, data)
  
    super(model, data)
    
    @file_suffix = "cutlist.csv"
  
  end
  
end


# Outputs a web page to view the cut list immediately. The web page can be 
# printed for quick cut listing.
class WebPageOutputFormat < OutputFormat
  
  def initialize(model, data)
    
    super(model, data)
    
  end
  
  def display_results
    
    ResultsWebUI.new.show(@data)
    
  end
  
end

