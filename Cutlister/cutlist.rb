

# This class controls the different list types for a cut list (e.g. Batched 
# Lists, Individual Lists, etc...)
# 
# Each sub-class of the Cutlist class is automatically added to the list of 
# "List Types" in the UI. If you sub-class this class your new class will 
# display in the list automatically (after SketchUp is restarted or the 
# plug-in is reloaded).
# 
# All sub-classed cut list types must have a `@name` and a `@display_name` 
# class variable in order to show up in the list. If you do not declare are 
# name and display_name your class will not show up. 
# 
# It is optional butrecommended to add in a `@description` class variable 
# that briefly describes what your class does so that it can be show in 
# the UI as help text.
class Cutlist
  
  def initialize(model, renderer, parts, options)
    
    @model = model
    @renderer = renderer
    @parts = parts
    @options = options
    @title = title()
    
    puts "[Cutlist.initialize] @model: #{@model}" if $debug
    puts "[Cutlist.initialize] @renderer: #{@renderer}" if $debug
    puts "[Cutlist.initialize] @parts: #{@parts}" if $debug
    puts "[Cutlist.initialize] @options: #{@options}" if $debug
    
  end
  
  # Add a display name property for displaying in the web dialog UI.
  def self.display_name
    
    @display_name
    
  end

  # Add a description property for displaying in the web dialog UI.
  def self.description

    @description

  end
  
  # This method creates a title for the page.
  def title
    
    title = "Cutlist for: #{@model.title}"
    
    puts "[Cutlist.title]: #{title}" if $debug
    
    title
    
  end
  
  # This method creates a heading for the page.
  # 
  # This is called once at the top of the file and can be used to construct 
  # the page framework or declare doctypes, etc...
  def heading(title = @title, opts = {})
    
    heading = @renderer.heading(title, opts)
    
    puts "[Cutlist.heading]: #{heading}" if $debug
    
    heading
    
  end
  
  # This method creates a title for the page.
  def page_title
    
    page_title = @renderer.title title()
    
    puts "[Cutlist.page_title]: #{page_title}" if $debug
    
    page_title
    
  end
  
  # This method constructs all the rows for a particular section.
  def rows(parts = @parts)
    
    @renderer.rows(parts)
    
  end
  
  # This method constructs a heading for a section.
  def section_heading(label)
    
    @renderer.section_heading(label)
    
  end
  
  # This method returns a footer for a section. 
  def section_footer(parts = @parts)
    
    # Count the parts (hardware), calculate the board feet (solid stock), or 
    # calculate the square footage (sheet goods).
    
    # TODO: Support metric and emperical units.
    
    @renderer.section_footer(parts)
    
  end
  
  # This method constructs a footer for the page.
  # 
  # This can be used to close out the page formatting or give a summary of 
  # content.
  def footer
    
    @renderer.footer()
    
  end
  
  # This is the main cutlist method that constructs the cutlist.
  # 
  # It calls the proper renderer, grabs the formatted content and then 
  # outputs the final formatted cut list data.
  # 
  # If you want a different format, over-ride this class in your sub-class.
  def build
    
    puts "[Cutlist.build] Building cutlist..." if $debug
    
    data = heading().to_s
    
    data += page_title().to_s
    
    # Show sheet goods section.
    if @options["show_sheets"]
      
      if @parts.sheets != nil

        data += section_heading("Sheet Goods").to_s
        data += rows(@parts.sheets).to_s
        data += section_footer(@parts.sheets).to_s
        
      end
      
    end
    
    # Show solid stock section.
    if @options["show_solids"]
      
      if @parts.solids != nil
        
        data += section_heading("Solid Stock").to_s
        data += rows(@parts.solids).to_s
        data += section_footer(@parts.solids).to_s
        
      end
    
    end
    
    # Show hardware section.
    if @options["show_hardware"]
      
      if @parts.hardware != nil
        
        data += section_heading("Hardware").to_s
        data += rows(@parts.hardware).to_s
        data += section_footer(@parts.hardware).to_s
        
      end
    
    end
    
    data += footer().to_s
    
    # Return the results.
    data
    
  end
  
end


# Groups the cut list based on material/thickness.
# 
# This would result in a list that would have sections like: '3/4" Poplar', 
# '1/4" MDF', etc...
# 
# The sections are ordered first by material (alpha sort), then by size, 
# from largest to smallest.
# 
# This type of cutlist is usually used for doing batched cutting of material.
class BatchedCutlist < Cutlist
  
  def initialize(model, renderer, parts, options)
    
    super(model, renderer, parts, options)
    
  end
  
  @display_name = "Batched"
  @description = "This cut list is usually used for doing batched cutting of material."
  
  # def initialize(renderer, parts)
  #   
  #   super(renderer, parts)
  # 
  # end

  # TODO: Group items based on material/thickness.
  

  
end


# Groups the cut list based on cabinet number.
# 
# This type of cutlist is usually used when assembling cabinets.
class IndividualCutlist < Cutlist

  def initialize(model, renderer, parts, options)
    
    super(model, renderer, parts, options)
  
  end

  @display_name = "Individual"
  @description = "This cut list is usually used when assembling cabinets."
  
  # TODO: Group items based on cabinet number.
  def build
    
    data = heading(:css_location => "css/html-cutlist.css").to_s
    
    data += page_title().to_s
    
    # sheets = []
    # solids = []
    # hardware = []
    # 
    # @parts.each { |p| 
    #   case p['type']
    #     when 'sheet'
    #       sheets << p
    #     when 'solid'
    #       solids << p
    #     when 'hardware'
    #       hardware << p
    #   end
    # }
    
    
    # # Show sheet goods section.
    # if @options["show_sheets"]
    #   
    #   data += section_heading("Sheet Goods").to_s
    #   data += rows(@parts.sheets).to_s
    #   data += section_footer(@parts.sheets).to_s
    #   
    # end
    # 
    # # Show solid stock section.
    # if @options["show_solids"]
    #   
    #   data += section_heading("Solid Stock").to_s
    #   data += rows(@parts.solids).to_s
    #   data += section_footer(@parts.solids).to_s
    # 
    # end
    # 
    # # Show hardware section.
    # if @options["show_hardware"]
    #   
    #   data += section_heading("Hardware").to_s
    #   data += rows(@parts.hardware).to_s
    #   data += section_footer(@parts.hardware).to_s
    # 
    # end
    
    data += footer().to_s
    
    # Return the results.
    data
    
  end

end


# Returns a raw, unformatted cut list.
# 
# This will give you all the parts, unordered and ungrouped. This is useful if 
# you want a raw list of parts without sections, etc...
class FullCutlist < Cutlist
  
  def initialize(model, renderer, parts, options)
    
    super(model, renderer, parts, options)
    
  end

  @display_name = "Full"
  @description = "This cut list exports all the items, unformatted."

  # def initialize(renderer, parts)
  #   
  #   super(renderer, parts)
  #   
  # end

  # TODO: Output all content without grouping.
  
  def build
    
    data = heading(:css_location => "css/html-cutlist.css").to_s
    
    data += page_title().to_s
    
    data += rows(@parts.all).to_s

    # # Show sheet goods section.
    # if @options["show_sheets"]
    #   
    #   data += rows(@parts.sheets).to_s
    #   
    # end
    # 
    # # Show solid stock section.
    # if @options["show_solids"]
    #   
    #   data += rows(@parts.solids).to_s
    # 
    # end
    # 
    # # Show hardware section.
    # if @options["show_hardware"]
    #   
    #   data += rows(@parts.hardware).to_s
    # 
    # end
    
    data += footer().to_s
    
    # Return the results.
    data
    
  end

end
