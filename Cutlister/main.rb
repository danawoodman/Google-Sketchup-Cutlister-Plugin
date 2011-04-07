puts "[Cutlister.rb] Debugging is on." if CUTLISTER_DEBUG
puts "[Cutlister.rb] Version of Cutlister is: #{CUTLISTER_VERSION}" if CUTLISTER_DEBUG

# Load all the application files.
load File.join(CUTLISTER_BASE_PATH, 'Cutlister/utils.rb')
load File.join(CUTLISTER_BASE_PATH, 'Cutlister/parts.rb')
load File.join(CUTLISTER_BASE_PATH, 'Cutlister/gui.rb')
load File.join(CUTLISTER_BASE_PATH, 'Cutlister/renderers.rb')
load File.join(CUTLISTER_BASE_PATH, 'Cutlister/output_format.rb')
load File.join(CUTLISTER_BASE_PATH, 'Cutlister/cutlist.rb')

# NOTE: Load your own extensions here:
load File.join(CUTLISTER_BASE_PATH, 'Cutlister/extensions/labels.rb')


# Create a GUI instance that prompts for an interactive configuration, 
# producing the requested output formats.
def interactive_generator
  
  web_ui = ToolWebUI.new()
  web_ui.show
  
end

# Add content menu items, plugin menu item, etc...
if not file_loaded?(File.join(CUTLISTER_BASE_PATH, "Cutlister.rb"))
  
  # Add menu item in the "Plugins" main menu drop-down.
  plugins_menu = UI.menu("Plugins")
  plugins_menu.add_item("Cutlist Model") { interactive_generator }
  
  # Add context click menu item.
  UI.add_context_menu_handler do |context_menu|
    context_menu.add_separator
    context_menu.add_item("Cutlist Selection") { interactive_generator }
  end
  
end

file_loaded(File.join(CUTLISTER_BASE_PATH, "Cutlister.rb"))