class PartList
  
  def initialize(model, selection, options)
    
    @model = model
    @selection = selection
    @options = options
    @parts = []
    
    # Look through the options and get the sheet_materials and solid_materials lists.
    options.each { |key, value|
    
      case key
        when "sheet_materials"
          @sheet_materials = value ? value : []
        when "solid_materials"
          @solid_materials = value ? value : []
      end
      
    }

    # Go through and collect all the parts in the selection.
    @entities = get_parts(@selection)
    
    puts "[PartList.initialize] @model: #{@model}" if CUTLISTER_DEBUG
    puts "[PartList.initialize] @selection: #{@selection}" if CUTLISTER_DEBUG
    puts "[PartList.initialize] options: #{options}" if CUTLISTER_DEBUG
    puts "[PartList.initialize] @sheet_materials: #{@sheet_materials}" if CUTLISTER_DEBUG
    puts "[PartList.initialize] @solid_materials: #{@solid_materials}" if CUTLISTER_DEBUG
    puts "[PartList.initialize] @entities: #{@entities}\n\n" if CUTLISTER_DEBUG
    
  end

  # Return all the sheet good parts.
  def sheets
    
    puts "[PartList.sheets] Showing sheet parts..." if CUTLISTER_DEBUG

    part_array = []
    
    @parts.each { |p|
      
      if p.is_sheet
        
        part_array << p
        
      end
      
    }
    
    part_array.empty? ? nil : to_hash(part_array)

  end
  
  # Return all the solid stock parts.
  def solids
    
    puts "[PartList.solids] Showing solid parts..." if CUTLISTER_DEBUG
    
    part_array = []
    
    @parts.each { |p|
      
      if p.is_solid
        
        part_array << p
        
      end
      
    }
    
    part_array.empty? ? nil : to_hash(part_array)
    
  end
  
  # Return all the hardware parts (anything that is not a sheet or solid.)
  def hardware
    
    puts "[PartList.hardware] Showing hardware parts..." if CUTLISTER_DEBUG

    part_array = []
    
    @parts.each { |p|
      
      if p.is_hardware
        
        part_array << p
        
      end
      
    }
    
    part_array.empty? ? nil : to_hash(part_array)

  end
  
  def all
    
    parts = to_hash(@parts)
    
    # For each part, set the quantity to 1 (since we are not grouping them).
    parts.each { |p|
      p['quantity'] = 1
    }
    
    parts
    
  end
  
  # Returns all the parts in a hash that has all duplicate parts removed.
  def grouped
    
    # Get a hash of the parts.
    parts = to_hash(@parts)
    
    # Create a list that has all the unique parts by first cloning the list 
    # of parts and then grabbing all the unique values.
    unique_parts = Marshal.load(Marshal.dump(parts))
    unique_parts.uniq_hash_array!

    # Compare the full parts list to the unique parts list, increasing the 
    # quantity of a part by 1 each time a duplicate is found.
    if unique_parts
      
      parts.each { |p|
        unique_parts.each { |u|
          # We compare the fields of the two parts to make sure they are the same. 
          # We don't need to compare all the values such as area or volume as they
          # are calculated off of the thickness/width/length.
          if u['sub_assembly'] == p['sub_assembly'] and 
                u['part_name'] == p['part_name'] and 
                u['material'] == p['material'] and 
                u['thickness'] == p['thickness'] and 
                u['width'] == p['width'] and 
                u['length'] == p['length']
            u['quantity'] += 1
          end
        }
      }

      # Return the list of unique parts, with their incremented quantity values.
      unique_parts
      
    else
      
      # If there are no unique parts, that means every part is seperate and 
      # there are no duplicates, so we can just return the original list of parts.
      parts
      
    end
    
  end
  
  # Returns all the parts as an array of hashes.
  def to_hash(parts_array)
    
    parts_array.collect! { |p| 
      # {
      #   'sub_assembly' => p.sub_assembly,
      #   'part_name' => p.part_name,
      #   'quantity' => p.quantity,
      #   'material' => p.material,
      #   'is_sheet' => p.is_sheet,
      #   'is_solid' => p.is_solid,
      #   'is_hardware' => p.is_hardware,
      #   'thickness' => p.thickness,
      #   'width' => p.width,
      #   'length' => p.length,
      #   'area' => p.area,
      #   'volume' => p.volume,
      #   'square_feet' => p.square_feet,
      #   'board_feet' => p.board_feet,
      # }
      p.to_hash
    }
    
  end
  
  # Add a part to the list of parts in the model.
  def add_part(part)
    
    @parts.push(part)
    
  end
  
  # Remove a part from the list.
  def remove_part(part)
    
    @parts.slice!(part)
    
  end
  
  # Get all the parts within a list of entities. This excludes entites in the 
  # model that are not groups/components, as well as entites that are hidden.
  # 
  # We set sub_assembly_name to "N/A" as a default because if a part is cut 
  # listed that does not have a parent group/component, then it does not have a
  # sub assembly name to use. 
  def get_parts(selection, sub_assembly_name="N/A")
    
    puts "[PartList.get_parts] Getting entities...\n\n" if CUTLISTER_DEBUG
    puts "[PartList.get_parts] sub_assembly_name: #{sub_assembly_name}\n\n" if CUTLISTER_DEBUG
    
    # parts_array = []
    
    level_has_parts = false
    
    # Collect all the parts that are components or groups and add them to `array`.
    selection.each { |s| 
      
      # Only cut list components or groups.
      if (s.typename == "ComponentInstance" || s.typename == "Group") && s.layer.visible?
        
        # Set default values...
        is_sheet = false
        is_solid = false
        is_hardware = true
        material = nil
        sub_parts = nil
        
        # If the part is a Component, get it's name, material and sub parts 
        # based on it's "definition".
        if s.typename == "ComponentInstance"
          
          part_name = s.definition.name
          sub_parts = s.definition.entities
          material = s.definition.material
          
          puts "[PartList.get_parts] (ComponentInstance) part_name: #{part_name}" if CUTLISTER_DEBUG
          puts "[PartList.get_parts] (ComponentInstance) sub_parts: #{sub_parts}\n\n" if CUTLISTER_DEBUG
        
        # If the part is a Group, get it's name, material and sub parts 
        # based on it's property methods.
        elsif s.typename == "Group"
          
          part_name = s.name
          sub_parts = s.entities
          material = s.material
          
          puts "[PartList.get_parts] (Group) part_name: #{part_name}" if CUTLISTER_DEBUG
          puts "[PartList.get_parts] (Group) sub_parts: #{sub_parts}\n\n" if CUTLISTER_DEBUG
          
          # # TODO: Do we need to include the below code? I believe it is for older
          # # versions of SketchUp...
          # if sub_assembly_name == nil || sub_assembly_name == ""
          #   
          #   # Let's see if this is a copy of a group which might already 
          #   # have a name.
          #   sub_assembly_name = getGroupCopyName(p)
          #   
          #   if sub_assembly_name != nil && sub_assembly_name != ""
          #     
          #     puts "[PartList.get_parts] (Group) Group had no name but is assigned the name \"#{sub_assembly_name}\" based on it's parent." if CUTLISTER_DEBUG
          #   
          #   end
          #   
          # end
          
        end

        # If there is a material, set it to the material display_name, if not 
        # set it to "N/A".
        material = material ? material.display_name : "N/A"

        puts "[PartList.get_parts] material: #{material}\n\n" if CUTLISTER_DEBUG
        
        # Do a case-insensitive search on all the sheet materials to see if the 
        # material matches.
        if @sheet_materials
          
          @sheet_materials.each { |m|

            if m.index(/#{material}/i) != nil

              is_sheet = true
              is_solid = false
              is_hardware = false
              
              puts "[PartList.get_parts] (#{material}) Sheet part found...\n\n" if CUTLISTER_DEBUG

            end

          }
          
        end
        
        # Do a case-insensitive search on all the solid materials to see if the 
        # material matches.
        if @solid_materials
          
          @solid_materials.each { |m|

            if m.index(/#{material}/i) != nil
              
              is_sheet = false
              is_solid = true
              is_hardware = false
              
              puts "[PartList.get_parts] (#{material}) Solid part found...\n\n" if CUTLISTER_DEBUG

            end

          }
          
        end
        
        sub_parts = get_parts(sub_parts, part_name)     
       
        # If the part does not have sub_parts or if it is a hardware part 
        # then we add it to the list of parts.
        if !sub_parts
          
          puts "[PartList.get_parts] Part does not have sub_parts...\n\n" if CUTLISTER_DEBUG
          
          # Create a new part.
          part = Part.new(s, sub_assembly_name, part_name, material, is_sheet, is_solid, is_hardware, @options)

          # Add the new part to the database of parts.
          add_part(part)
        
        # If the part has sub_parts, then we do not add it, as it is just 
        # a group of other parts.
        else
          
          puts "[PartList.get_parts] Part has sub_parts...\n\n" if CUTLISTER_DEBUG
          
        end
        
        level_has_parts = true
        
      end
      
    }
    
    # If it gets here, than this level has parts.
    level_has_parts
    
    # puts "[PartList.get_parts] parts_array: #{parts_array}" if CUTLISTER_DEBUG
    # 
    # # Debug each part...
    # parts_array.each { |p|
    #   
    #   puts "[PartList.get_parts] part: #{p.typename}, #{p.cabinet_name}, #{p.quantity}, #{p.width},  #{p.length}, #{p.thickness}, #{p.material}, #{p.area}, #{p.volume}, #{p.board_feet}, #{p.square_feet}\n"
    #   
    # } if CUTLISTER_DEBUG
    # 
    # puts "\n\n" if CUTLISTER_DEBUG
    # 
    # parts_array # Returns the array of parts.
    
  end
  
  # Returns true if there are no parts, false if there are parts.
  def empty?
    
    @parts.length == 0
    
  end
  
end


class Part
  
  attr_accessor :sub_assembly, 
                :part_name, 
                :quantity, 
                :material,
                :is_sheet,
                :is_solid,
                :is_hardware,
                :thickness,
                :width,
                :length,
                :area,
                :volume,
                :square_feet,
                :board_feet
  
  def initialize(entity, sub_assembly_name, part_name, material, is_sheet, 
                is_solid, is_hardware, options)
    
    @sub_assembly = sub_assembly_name ? sub_assembly_name : 'N/A'
    @part_name = part_name ? part_name : 'N/A'
    @material = material
    @is_sheet = is_sheet
    @is_solid = is_solid
    @is_hardware = is_hardware
    @quantity = 0
    @options = options
        
    # Find the bounding box for the part.
    boundingBox = entity.bounds
    
    # If the part is a component instance, get the definition bounds.
    if entity.respond_to? "definition"
      
     boundingBox = entity.definition.bounds
     
    end
    
    # Get the transformation of the component.
    trans = entity.transformation.to_a
    scale_x = Math.sqrt(trans[0]**2 + trans[1]**2 + trans[2]**2)
    scale_y = Math.sqrt(trans[4]**2 + trans[5]**2 + trans[6]**2)
    scale_z = Math.sqrt(trans[8]**2 + trans[9]**2 + trans[10]**2)    
    
    # Get the width, height and depth of the part.
    width = boundingBox.width * scale_x
    height = boundingBox.height * scale_y
    depth = boundingBox.depth * scale_z
    
    if @options['round_dimensions']
      width = format("%0.4f", width).to_f
      height = format("%0.4f", height).to_f
      depth = format("%0.4f", depth).to_f
    end
    
    # Get the sorted dimensions
    sizes = get_sorted_array([width, height, depth])
    
    # Assuming the longest dimension is the length and shortest is the thickness
    @thickness = sizes[0]
    @width = sizes[1]
    @length = sizes[2]
    
    # Calculate the dimensions of the part.
    # dimension_calculations()
    @area = @length * @width
    @volume = @area * @thickness
    @square_feet = @area / 144
    @board_feet = @volume / 144
    
    # Debugging...
    puts "[Part.initialize] @sub_assembly: #{@sub_assembly}" if CUTLISTER_DEBUG
    puts "[Part.initialize] @part_name: #{@part_name}" if CUTLISTER_DEBUG
    puts "[Part.initialize] @material: #{@material}" if CUTLISTER_DEBUG
    puts "[Part.initialize] @is_sheet: #{@is_sheet}" if CUTLISTER_DEBUG
    puts "[Part.initialize] @is_solid: #{@is_solid}" if CUTLISTER_DEBUG
    puts "[Part.initialize] @is_hardware: #{@is_hardware}" if CUTLISTER_DEBUG
    puts "[Part.initialize] @thickness: #{@thickness}" if CUTLISTER_DEBUG
    puts "[Part.initialize] @width: #{@width}" if CUTLISTER_DEBUG
    puts "[Part.initialize] @length: #{@length}\n\n" if CUTLISTER_DEBUG
    puts "[Part.initialize] @area: #{@area}\n\n" if CUTLISTER_DEBUG
    puts "[Part.initialize] @volume: #{@volume}\n\n" if CUTLISTER_DEBUG
    puts "[Part.initialize] @square_feet: #{@square_feet}\n\n" if CUTLISTER_DEBUG
    puts "[Part.initialize] @board_feet: #{@board_feet}\n\n" if CUTLISTER_DEBUG
    
    
    # @lengthInFeet = @length.to_feet
    # @material = material
    # @name = strip(name, @length.to_s, @width.to_s, @thickness.to_s )
    # @subAssemblyName = strip(subAssemblyName, @length.to_s, @width.to_s, @thickness.to_s )
    # @canRotate = true
    # @metricVolume = metricVolume
    # @metric = metricModel?
    # @locationOnBoard = nil
    
  end
  
  # 
  def to_hash
    {
      'sub_assembly' => self.sub_assembly,
      'part_name' => self.part_name,
      'quantity' => self.quantity,
      'material' => self.material,
      'is_sheet' => self.is_sheet,
      'is_solid' => self.is_solid,
      'is_hardware' => self.is_hardware,
      'thickness' => self.thickness,
      'width' => self.width,
      'length' => self.length,
      'area' => self.area,
      'volume' => self.volume,
      'square_feet' => self.square_feet,
      'board_feet' => self.board_feet,
    }
  end

  # def dimension_calculations
  # 
  #   area = @length * @width
  #   volume = area * @thickness
  #   square_feet = area / 144
  #   board_feet = volume / 144
  #   
  #   # NOTE: Should this be integers or strings???
  #   @area = area.to_s
  #   @volume = volume.to_s
  #   @square_feet = square_feet.to_s
  #   @board_feet = board_feet.to_s
  # 
  # end

  # Bubble sort: Sorts in ascending order.
  def get_sorted_array(array)

    size = array.size()
    pass = size

    for i in (0..pass - 2)

      for j in (0..pass - 2)

        if (array[j + 1] < array[j])

          tmp = array[j]
          array[j] = array[j + 1]
          array[j + 1] = tmp

        end

      end

    end

    return array

  end

  # def typename
  #   
  #   'foobar'
  #   
  # end

  # def sub_assembly
  #   
  #   # If there is a sub_assembly_name, than use that, else show "N/A".
  #   @sub_assembly ? @sub_assembly : 'N/A'
  #   
  # end
  # 
  # def part_name
  #   
  #   # If there is a part_name, show that, or else show `N/A'.
  #   @part_name ? @part_name : 'N/A'
  #   
  # end
  # 
  # def quantity
  #   
  #   # TODO: Calculate quantities...
  #   '1'
  #   
  # end
  
  # def width
  #   
  #   @width
  #   
  # end
  # 
  # def length
  #   
  #   @length
  #   
  # end
  # 
  # def thickness
  #   
  #   @thickness
  #   
  # end
  # 
  # def material
  #   
  #   @material
  #   
  # end
  # 
  # def area
  #   
  #   @area.to_s
  #   
  # end
  # 
  # def volume
  #   
  #   @volume.to_s
  #   
  # end
  # 
  # def square_feet
  #   
  #   @square_feet.to_s
  #   
  # end
  # 
  # def board_feet
  #   
  #   @board_feet.to_s
  #   
  # end

  # Checks to see if a part is a sheet. Returns true if it is, false if not.
  # def is_sheet
  #   
  #   puts "[Part.is_sheet]: true\n\n" if CUTLISTER_DEBUG
  #   
  #   @is_sheet
  #   # is_sheet = false
  #   #     
  #   #     # Do a case-insensitive search on all the sheet materials to see if the 
  #   #     # material matches.
  #   #     @sheet_materials.each { |m|
  #   #       
  #   #       if m.index(/#{@material}/i) != nil
  #   #         
  #   #         is_sheet = true
  #   #         
  #   #       end
  #   #       
  #   #     }
  #   #     
  #   #     puts "[Part.is_sheet]: (#{@material}) #{is_sheet}" if CUTLISTER_DEBUG
  #   #     
  #   #     is_sheet
  #   
  # end
  # 
  # # Checks to see if a part is a solid. Returns true if it is, false if not.
  # def is_solid
  #   
  #   puts "[Part.is_solid]: true\n\n" if CUTLISTER_DEBUG
  #   
  #   @is_solid
  #   
  #   # is_solid = false
  #   #     
  #   #     # Do a case-insensitive search on all the sheet materials to see if the 
  #   #     # material matches.
  #   #     @solid_materials.each { |m|
  #   #       
  #   #       if m.index(/#{@material}/i) != nil
  #   #         
  #   #         is_solid = true
  #   #         
  #   #       end
  #   #       
  #   #     }
  #   #     
  #   #     puts "[Part.is_solid]: (#{@material}) #{is_solid}" if CUTLISTER_DEBUG
  #   #     
  #   #     is_solid
  #   
  # end
  # 
  # # Checks to see if a part is hardware. Returns true if it is, false if not.
  # def is_hardware
  #   
  #   puts "[Part.is_hardware]: true\n\n" if CUTLISTER_DEBUG
  #   
  #   @is_hardware
  #   
  #   # # If the part is not a sheet or a solid, than it is assumed to be hardware.
  #   #     is_hardware = is_sheet && is_solid ? false : true
  #   #     
  #   #     puts "[Part.is_hardware]: (#{@material}) #{is_hardware}" if CUTLISTER_DEBUG
  #   #     
  #   #     is_hardware
  #   
  # end
  
end


# # This class represents sheet goods.
# # 
# # Sheet goods usually represent items such as plywood, MDF, or anything that 
# # is in the form of a sheet. The plug-in interprets anything in your 
# # "Sheet Goods" list as a sheet part.
# # 
# # We need to calculate the square footage of sheets because that is the 
# # common unit of measure.
# class SheetGood < Part
#   
# end
# 
# 
# # This class represents a part of solid stock.
# # 
# # Solid stock usually represents boards of lumber such as planks. The plug-in 
# # interprets anything in your "Solid Stock" list as a solid part.
# # 
# # We need to calculate the board feet of solid stock because that is the 
# # common unit of measure.
# class SolidStock < Part
#   
# end
# 
# 
# # This class represents a hardware part.
# # 
# # Hardware is basically anything other than a sheet good or solid stock. It
# # usually represents things like door hinges, handles, drawer slides and the 
# # like but could represent anything that has not been defined in the sheet 
# # good or solid stock list of keywords.
# # 
# # We need to calculate the number of hardware parts because that is the only 
# # logical way to measure a collection of hardware because hardware could be 
# # anything.
# # 
# # If you find a part that is getting classified as hardware that should be 
# # solid stock or sheet goods, make sure it has a material applied to it and 
# # that tha material is in either the sheet good or solid part lists in the UI.
# class Hardware < Part
#   
# end
