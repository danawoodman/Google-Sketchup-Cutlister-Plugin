

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
  
  def build
    
    data = heading(:css_location => "css/html-cutlist.css").to_s
    
    data += page_title().to_s
    
    # Get all the parts in an array of part hashes.
    all_parts = @parts.grouped

    # # Sort parts.
    # all_parts = all_parts.sort { |a, b|
    #   a['material'] <=> b['material']
    #   # a['thickness'] <=> b['thickness']
    #   # a['width'] <=> b['width']
    #   # a['length'] <=> b['length']
    # }

    # Create an empty array of materials.
    materials = []

    # Put all the materials in the list
    all_parts.each  { |p|
      materials.push(p['material']) 
    }

    # Make sure there is only one of each material.
    materials = materials.uniq

    # Create a blank hash to put sorted parts into.
    grouped_parts = {}

    # Create a new list of hashes that represent the material and then the parts 
    # that are of that material (a blank hash).
    materials.each { |m| 
      grouped_parts[m] = {}
    }

    # Loop through each part, adding it to the right key in the sorted_list.
    all_parts.each { |p| 

     # Go through the list of materials.
     materials.each { |m|

        if p['material'] == m

          # Check to see if there is a key for this thickness and if there is 
          # append the part to the array of parts.
          if grouped_parts[m][p['thickness']]
            grouped_parts[m][p['thickness']] += [p]
          # If there isn't a key for this thickness, create it now and add the 
          # part array.
          else
            grouped_parts[m][p['thickness']] = [p]
          end

        end

      }

    }
    # Sort by materials.
    parts_by_material = grouped_parts.sort { |a,b|
      a[0] <=> b[0]
    }

    # List all the parts, grouped.
    parts_by_material.each { |t| # t for thickness.

      # Sort thicknesses.
      parts_by_thickness = t[1].sort { |a,b|
        a[0] <=> b[0]
      }
      parts_by_thickness.reverse!

      # Go through each thickness key.
      parts_by_thickness.each { |p| # p for parts
        # TODO: Apply dimensioning here...
        data += section_heading("#{p[0].to_fraction} #{t[0]}")

        # Sort parts by width, then length.
        parts = p[1].sort { |a,b|
          a['width'] <=> b['width']
          # a['length'] <=> b['length']
        }
        parts.reverse!
        
        # Create a parts array to store the parts in.
        parts_array = []
        
        # Go through the parts that are of a specific thickness.
        parts.each { |part| 
          
          # Check if part is a sheet good.
          if @options["show_sheets"] && part['is_sheet']

            parts_array.push(part)

          end

          # Check if part is solid stock.
          if @options["show_solids"] && part['is_solid']

            parts_array.push(part)

          end

          # Check if part is hardware.
          if @options["show_hardware"] && part['is_hardware']

            parts_array.push(part)

          end
          # puts "#{p['sub_assembly']} -- #{p['part_name']} -- #{p['quantity']} -- #{p['material']} -- Sheet? #{p['is_sheet']} -- Solid? #{p['is_solid']} -- Hardware? #{p['is_hardware']} -- #{p['width']} x #{p['length']} x #{p['thickness']}"
        
        }
        
        data += rows(parts_array)
        
        # TODO: Put section footer here, if needed
        
      }
    }
    
    data += footer().to_s
    
    # Return the results.
    data
    
  end
  
  
end


# Groups the cutlist based on cabinet number.
# 
# This type of cutlist is usually used when assembling cabinets and it consists 
# of a cutlist grouped by cabinet name.
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
    
    # Get all the parts in a hash.
    all_parts = @parts.grouped

    # Create an empty array of sub_assemblys.
    sub_assemblies = []

    # Put all the sub_assembly in the list
    all_parts.each  { |p|
      sub_assemblies.push(p['sub_assembly']) 
    }

    # Make sure there is only one of each sub_assembly.
    sub_assemblies = sub_assemblies.uniq

    # Create a blank hash to put grouped parts into.
    grouped_parts = {}

    # Create a new list of hashes that represent the sub_assembly and then the parts 
    # that are of that sub_assembly.
    sub_assemblies.each { |s| 
      grouped_parts[s] = []
    }

    # Loop through each part, adding it to the right key in the grouped_parts.
    all_parts.each { |p| 

     # Go through the list of sub_assemblys.
     sub_assemblies.each { |s|

        if p['sub_assembly'] == s
          
          # If there is already a key that equals the sub_assembly, add the part
          # to the existing value. This happens if there is already a hash 
          # key/value for the given sub_assembly.
          if grouped_parts[s]
            grouped_parts[s] += [p]
          # If there is not a key that equals the sub_assembly, create a new 
          # hash key for the sub assembly and add the part to it. This happens 
          # the first time a parts sub_assembly equals the the sub_assembly in 
          # the list of sub_assemblys.
          else
            grouped_parts[s] = [p]
          end

        end

      }

    }
    
    grouped_parts.each { |s|
      
      # Create a heading for each sub_assembly.
      data += section_heading("#{s[0]}")
      
      # Create an empty array of parts for each sub_asembly.
      parts_array = []
      
      # Go through the list of parts for each sub_assembly
      s[1].each { |part|
            
        # Check if part is a sheet good.
        if @options["show_sheets"] && part['is_sheet']

          parts_array.push(part)

        end

        # Check if part is solid stock.
        if @options["show_solids"] && part['is_solid']

          parts_array.push(part)

        end

        # Check if part is hardware.
        if @options["show_hardware"] && part['is_hardware']

          parts_array.push(part)

        end
          
      }
      
      # Add the array of parts to the data for the cut list.
      data += rows(parts_array)
      
    }
    
    
    
    
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
