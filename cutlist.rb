# Copyright 2006-2010 daltxguy, Vendmr
# Based on CutList.rb, Copyright 2005, CptanPanic

# This extension produces a cutlist from a woodworking model and a layout of the part
# on boards or sheet goods.

# Permission to use, copy, modify, and distribute this software for
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
require 'sketchup.rb'
load 'cutlist/CutListAndMaterials.rb'


# create a GUI instance that prompts for an interactive configuration, producing the requested output formats
def interactive_generator
  webGui = WebGui.new("")
  webGui.start
end

# Add things to the Plugins menu
# Add CutList main entry 
# "Cut List" offers an html gui to select options and produce html and/or file output 
if( not file_loaded?("cutlist.rb") )
  add_separator_to_menu("Plugins")
  
  #plugins_menu = UI.menu("Plugins").add_submenu("Cut List")
  plugins_menu = UI.menu("Plugins")
  
  plugins_menu.add_item("Cut List") { interactive_generator }
  # no longer supported
  #plugins_menu.add_item("SU5") { fixed_configuration_generator }
end 

file_loaded("cutlist.rb")
#-----------------------------------------------------------------------------

