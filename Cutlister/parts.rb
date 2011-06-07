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
    
    if $cutlister_debug
      puts "[PartList.initialize] @model: #{@model}"
      puts "[PartList.initialize] @selection: #{@selection}"
      puts "[PartList.initialize] options: #{options}"
      puts "[PartList.initialize] @sheet_materials: #{@sheet_materials}"
      puts "[PartList.initialize] @solid_materials: #{@solid_materials}"
      puts "[PartList.initialize] @entities: #{@entities}\n\n"
    end
    
  end

  # Return all the sheet good parts.
  def sheets
    
    puts "[PartList.sheets] Showing sheet parts..." if $cutlister_debug

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
    
    puts "[PartList.solids] Showing solid parts..." if $cutlister_debug
    
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
    
    puts "[PartList.hardware] Showing hardware parts..." if $cutlister_debug

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
    
    puts "[PartList.get_parts] Getting entities...\n\n" if $cutlister_debug
    puts "[PartList.get_parts] sub_assembly_name: #{sub_assembly_name}\n\n" if $cutlister_debug
    
    # parts_array = []
    
    level_has_parts = false
    
    # Collect all the parts that are components or groups and add them to `array`.
    selection.each { |s|
      
      # Store wether or not this part is a component or group.
      is_group = s.is_a? Sketchup::Group
      is_component = s.is_a? Sketchup::ComponentInstance
      
      # Only cut list components or groups.
      if (is_component || is_group) && s.layer.visible?
        
        # Set default values...
        is_sheet = false
        is_solid = false
        is_hardware = true
        material = nil
        sub_parts = nil
        
        # If the part is a Component, get it's name, material and sub parts 
        # based on it's "definition".
        if is_component
          
          part_name = s.definition.name
          sub_parts = s.definition.entities
          material = s.definition.material
          
          puts "[PartList.get_parts] (ComponentInstance) part_name: #{part_name}" if $cutlister_debug
          puts "[PartList.get_parts] (ComponentInstance) sub_parts: #{sub_parts}\n\n" if $cutlister_debug
        
        # If the part is a Group, get it's name, material and sub parts 
        # based on it's property methods.
        else is_group
          
          part_name = s.name
          sub_parts = s.entities
          material = s.material
          
          puts "[PartList.get_parts] (Group) part_name: #{part_name}" if $cutlister_debug
          puts "[PartList.get_parts] (Group) sub_parts: #{sub_parts}\n\n" if $cutlister_debug
          
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
          #     puts "[PartList.get_parts] (Group) Group had no name but is assigned the name \"#{sub_assembly_name}\" based on it's parent." if $cutlister_debug
          #   
          #   end
          #   
          # end
          
        end

        # If there is a material, set it to the material display_name, if not 
        # set it to "N/A".
        material = material ? material.display_name : "N/A"

        puts "[PartList.get_parts] material: #{material}\n\n" if $cutlister_debug
        
        # Do a case-insensitive search on all the sheet materials to see if the 
        # material matches.
        if @sheet_materials
          
          @sheet_materials.each { |m|

            if m.index(/#{material}/i) != nil

              is_sheet = true
              is_solid = false
              is_hardware = false
              
              puts "[PartList.get_parts] (#{material}) Sheet part found...\n\n" if $cutlister_debug

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
              
              puts "[PartList.get_parts] (#{material}) Solid part found...\n\n" if $cutlister_debug

            end

          }
          
        end
        
        sub_parts = get_parts(sub_parts, part_name)     
       
        # If the part does not have sub_parts or if it is a hardware part 
        # then we add it to the list of parts.
        if !sub_parts
          
          puts "[PartList.get_parts] Part does not have sub_parts...\n\n" if $cutlister_debug
          
          # Create a new part.
          part = Part.new(s, sub_assembly_name, part_name, material, is_sheet, is_solid, is_hardware, @options)

          # Add the new part to the database of parts.
          add_part(part)
        
        # If the part has sub_parts, then we do not add it, as it is just 
        # a group of other parts.
        else
          
          puts "[PartList.get_parts] Part has sub_parts...\n\n" if $cutlister_debug
          
        end
        
        level_has_parts = true
        
      end
      
    }
    
    # If it gets here, than this level has parts.
    level_has_parts
    
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
    if $cutlister_debug
      puts "[Part.initialize] @sub_assembly: #{@sub_assembly}" 
      puts "[Part.initialize] @part_name: #{@part_name}"
      puts "[Part.initialize] @material: #{@material}"
      puts "[Part.initialize] @is_sheet: #{@is_sheet}"
      puts "[Part.initialize] @is_solid: #{@is_solid}"
      puts "[Part.initialize] @is_hardware: #{@is_hardware}"
      puts "[Part.initialize] @thickness: #{@thickness}"
      puts "[Part.initialize] @width: #{@width}"
      puts "[Part.initialize] @length: #{@length}"
      puts "[Part.initialize] @area: #{@area}"
      puts "[Part.initialize] @volume: #{@volume}"
      puts "[Part.initialize] @square_feet: #{@square_feet}"
      puts "[Part.initialize] @board_feet: #{@board_feet}"
    end
    
  end
  
  # 
  def to_hash
    {
      'sub_assembly' => @sub_assembly,
      'part_name' => @part_name,
      'quantity' => @quantity,
      'material' => @material,
      'is_sheet' => @is_sheet,
      'is_solid' => @is_solid,
      'is_hardware' => @is_hardware,
      'thickness' => @thickness,
      'width' => @width,
      'length' => @length,
      'area' => @area,
      'volume' => @volume,
      'square_feet' => @square_feet,
      'board_feet' => @board_feet,
    }
  end

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
  
end
