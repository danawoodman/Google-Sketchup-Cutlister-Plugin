# 
# =Cutlister
# 
# A Google SketchUp plugin to generate customizable part cutlists.
# 
# Author::        Dana Woodman (mailto:dana@danawoodman.com)
# Copyright::     Copyright (c) 2010, Dana Woodman.
# Licence::       Please see the LICENCE file for licence information.
# 
# This file initiates the Cutlister plugin and loads all app files and settings.
#

require 'sketchup.rb'

# Toggle whether debugging is on or off ("true" means on, "false" means off).
$debug = false

puts "[Cutlister.rb] Debugging is on." if $debug

# Define globals.
$version = "1.0 beta"

puts "[Cutlister.rb] Version of Cutlister is: #{$version}" if $debug

# Load all the application files.
load 'Cutlister/utils.rb'
load 'Cutlister/parts.rb'
load 'Cutlister/gui.rb'
load 'Cutlister/renderers.rb'
load 'Cutlister/output_format.rb'
load 'Cutlister/cutlist.rb'
# NOTE: Load your own extensions here:
load 'Cutlister/extensions/labels.rb'

# Create a GUI instance that prompts for an interactive configuration, 
# producing the requested output formats.
def interactive_generator
  
  web_ui = ToolWebUI.new()
  web_ui.show
  
end

# Add content menu items, plugin menu item, etc...
if not file_loaded?("Cutlister.rb")
  
  # Add menu item in the "Plugins" main menu drop-down.
  plugins_menu = UI.menu("Plugins")
  plugins_menu.add_item("Cutlist Model") { interactive_generator }
  
  # Add context click menu item.
  UI.add_context_menu_handler do |context_menu|
    context_menu.add_separator
    context_menu.add_item("Cutlist Selection") { interactive_generator }
  end
  
end

file_loaded("Cutlister.rb")