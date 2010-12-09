














# # The main Cutlister class.
# # 
# # This class initializes all the default options and opens up the GUI. It also 
# # populates the Format and ListType lists.
# class Cutlister
#   
#   cutlist_default_options = {
#     
#     :format => "csv", # csv, html, etc...
#     :list_type => "individual", # individual, batched, full, etc...
#     :show_sheets => true,
#     :show_solids => true,
#     :show_hardware => true,
#     :sheet_materials => ["plywood", "mdf", "shop ply", "pf maple"],
#     :solid_materials => ["poplar", "cedar", "maple"],
#     
#   }
#   
#   puts "cutlist_default_options: #{cutlist_default_options}" if $debug
#   
#   def initialize
#     
#     @model = Sketchup.active_model
#     @selection = @model.selection
#     
#     puts "@model: #{@model}" if $debug
#     puts "@selection: #{@selection}" if $debug
#     
#     # TODO: If nothing selected, prompt to select all.
#     
#   end
#   
#   # This method gets all the registered output formats.
#   def get_output_formats
#     
#     # TODO: Create a list of the subclasses to be used in the UIGUI.
#     puts OutputFormat.subclasses if @debug
#     
#   end
#   
#   # This method gets all the registered cutlist types.
#   def get_cutlist_types
#     
#     # TODO: Create a list of the subclasses to be used in the UIGUI.
#     puts Cutlist.subclasses if @debug
#     
#   end
# 
#   # The start method is called when the Cutlister plugin is activated within 
#   # SketchUp.
#   def start
# 
#     get_cutlist_types # For debugging...
#     gui = UIGUI.new(@model)
#     puts "gui: #{gui}" if $debug
#     gui.display
# 
#   end
#   
# end
