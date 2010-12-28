class PartList
  
  def initialize(model, selection, options)
    
    @model = model
    @selection = selection
    options = options
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
    
    puts "[PartList.initialize] @model: #{@model}" if $debug
    puts "[PartList.initialize] @selection: #{@selection}" if $debug
    puts "[PartList.initialize] options: #{options}" if $debug
    puts "[PartList.initialize] @sheet_materials: #{@sheet_materials}" if $debug
    puts "[PartList.initialize] @solid_materials: #{@solid_materials}" if $debug
    puts "[PartList.initialize] @entities: #{@entities}\n\n" if $debug
    
  end

  # Return all the sheet good parts.
  def sheets
    
    puts "[PartList.sheets] Showing sheet parts..." if $debug

    part_array = []
    
    @parts.each { |p|
      
      if p.is_sheet
        
        part_array << p
        
      end
      
    }
    
    part_array.empty? ? nil : part_array

  end
  
  # Return all the solid stock parts.
  def solids
    
    puts "[PartList.solids] Showing solid parts..." if $debug
    
    part_array = []
    
    @parts.each { |p|
      
      if p.is_solid
        
        part_array << p
        
      end
      
    }
    
    part_array.empty? ? nil : part_array
    
  end
  
  # Return all the hardware parts (anything that is not a sheet or solid.)
  def hardware
    
    puts "[PartList.hardware] Showing hardware parts..." if $debug

    part_array = []
    
    @parts.each { |p|
      
      if p.is_hardware
        
        part_array << p
        
      end
      
    }
    
    part_array.empty? ? nil : part_array

  end
  
  def all
    
    @parts
    
  end
  
  # Returns a list of parts, grouping similar parts (e.g. duplicate parts...)
  def get_grouped_parts
    
    # TODO: Write logic for this method...
    
  end
  
  # Add a part to the list of parts in the model.
  def add_part(part)
    
    @parts.push(part)
    
  end
  
  # Get all the parts within a list of entities. This excludes entites in the 
  # model that are not groups/components, as well as entites that are hidden.
  # 
  # We set sub_assembly_name to "N/A" as a default because if a part is cut 
  # listed that does not have a parent group/component, then it does not have a
  # sub assembly name to use. 
  def get_parts(parts, sub_assembly_name = "N/A")
    
    puts "[PartList.get_parts] Getting parts...\n\n" if $debug
    puts "[PartList.get_parts] sub_assembly_name: #{sub_assembly_name}\n\n" if $debug
    
    # parts_array = []
    
    level_has_parts = false
    
    # Collect all the parts that are components or groups and add them to `array`.
    parts.each { |p| 
      
      # Only cut list components or groups.
      if (p.typename == "ComponentInstance" || p.typename == "Group") && p.layer.visible?
        
        # Set default values...
        is_sheet = false
        is_solid = false
        is_hardware = true
        material = nil
        sub_parts = nil
        
        # If the part is a Component, get it's name, material and sub parts 
        # based on it's "definition".
        if p.typename == "ComponentInstance"
          
          part_name = p.definition.name
          
          sub_parts = p.definition.entities
          
          material = p.definition.material
          
          puts "[PartList.get_parts] (ComponentInstance) part_name: #{part_name}" if $debug
          puts "[PartList.get_parts] (ComponentInstance) sub_parts: #{sub_parts}\n\n" if $debug
        
        # If the part is a Group, get it's name, material and sub parts 
        # based on it's property methods.
        elsif p.typename == "Group"
          
          part_name = p.name
          
          sub_parts = p.entities
          
          material = p.material
          
          puts "[PartList.get_parts] (Group) part_name: #{part_name}" if $debug
          puts "[PartList.get_parts] (Group) sub_parts: #{sub_parts}\n\n" if $debug
          
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
          #     puts "[PartList.get_parts] (Group) Group had no name but is assigned the name \"#{sub_assembly_name}\" based on it's parent." if $debug
          #   
          #   end
          #   
          # end
          
        end

        # If there is a material, set it to the material display_name, if not 
        # set it to "N/A".
        material = material ? material.display_name : "N/A"

        puts "[PartList.get_parts] material: #{material}\n\n" if $debug
        
        # Do a case-insensitive search on all the sheet materials to see if the 
        # material matches.
        if @sheet_materials
          
          @sheet_materials.each { |m|

            if m.index(/#{material}/i) != nil

              is_sheet = true
              is_solid = false
              is_hardware = false
              
              puts "[PartList.get_parts] (#{material}) Sheet part found...\n\n" if $debug

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
              
              puts "[PartList.get_parts] (#{material}) Solid part found...\n\n" if $debug

            end

          }
          
        end
        
        sub_parts = get_parts(sub_parts, part_name)     
       
        # If the part does not have sub_parts or if it is a hardware part 
        # then we add it to the list of parts.
        if !sub_parts
          
          puts "[PartList.get_parts] Part does not have sub_parts...\n\n" if $debug
          
          # Create a new part.
          part = Part.new(p, sub_assembly_name, part_name, material, is_sheet, is_solid, is_hardware)

          # Add the new part to the database of parts.
          add_part(part)
        
        # If the part has sub_parts, then we do not add it, as it is just 
        # a group of other parts.
        else
          
          puts "[PartList.get_parts] Part has sub_parts...\n\n" if $debug
          
        end
        
        level_has_parts = true
        
      end
      
    }
    
    # If it gets here, than this level has parts.
    level_has_parts
    
    # puts "[PartList.get_parts] parts_array: #{parts_array}" if $debug
    # 
    # # Debug each part...
    # parts_array.each { |p|
    #   
    #   puts "[PartList.get_parts] part: #{p.typename}, #{p.cabinet_name}, #{p.quantity}, #{p.width},  #{p.length}, #{p.thickness}, #{p.material}, #{p.area}, #{p.volume}, #{p.board_feet}, #{p.square_feet}\n"
    #   
    # } if $debug
    # 
    # puts "\n\n" if $debug
    # 
    # parts_array # Returns the array of parts.
    
  end
  
  # REMOVE:
  def getSubComponents(entityList, level, subAssemblyName)
    
    levelHasComponents = false
    
    for c in entityList
      
      inSelection = selection.contains? c
      
      # Sub components do not appear as part of the selection so let them 
      # through but only look at visible sub-components
      if (inSelection || level>1) && c.layer.visible?
        
        if c.typename == "ComponentInstance" || c.typename == "Group"
          # Get the name of the component or group or try the inferred name 
          # based on its parent if it is a group with no name.
          compName = nil
          
          if c.typename == "ComponentInstance"
            compName = c.definition.name
            puts "ComponentInstance with definition name: " + compName.to_s if $verboseComponentDiscovery
          
          elsif c.typename == "Group"
            compName = c.name
            puts "Group with name: " + compName.to_s if $verboseComponentDiscovery
            
            if compName == nil || compName == ""
              # Let's see if this is a copy of a group which might already 
              # have a name.
              compName = getGroupCopyName(c)
              
              if compName != nil && compName != ""
                puts "Group had no name but is assigned name '" + compName.to_s + "' based on its parent." if $verboseComponentDiscovery
              end
              
            end
            
          end
        
          # Get the material name for this part.
          partMaterialClass = c.material
          
          if partMaterialClass == nil
            partMaterial = getMaterial(c)
          else
            partMaterial = partMaterialClass.name
          end
          
          # Compare the "part" words entered by the user to the entity name 
          # or to the material name to find the non-cutlisted parts.
          # 
          # If this is a hardware part, then we are done with this part.
          if isPartOrSheet( @@options[:cutlist_Options][:partWords], partMaterial ) || isPartOrSheet( @@options[:cutlist_Options][:partWords], compName )
            @partList.add(compName)
            puts "Adding part name " + compName.to_s + " (level: " + level.to_s  + ") as a hardware part since material or name matched."  if $verboseComponentDiscovery
            # Since a part was added, mark this level as having components.
            levelHasComponents = true
            next # Move on to the next part at this level.
          end
          
          # If it is not a hardware part, then for this component or group, 
          # go a level deeper to see if it has sub-components.
          subList = nil
          if c.typename == "ComponentInstance"
            subList = c.definition.entities
          elsif c.typename == "Group"
            subList = c.entities
          end
          
          # Go one level deeper if we found a type of part that might have 
          # sub-parts which we want to add to our list.
          # 
          # Note: this calls itself recursively until there are no 
          # sub-components at the particular level we are looking at.
          # 
          # compName is the name of the current part which we are exploring 
          # to a deeper level (e.g. the subassembly name).
          # 
          # Even if this part is ultimtely not added (because it has 
          # sub-conponents) we can record which sub-assembly it belongs to 
          # its child parts.
          hasSubComponents = getSubComponents(subList, level+1, compName) 
          
          if !hasSubComponents
            puts "Adding part name '" + compName.to_s + "' (sub-assembly: " + subAssemblyName.to_s + ", level:" + level.to_s  + ", since level:" + (level + 1).to_s + ", has no sub-components)." if $verboseComponentDiscovery
            # Allows names with - + at start etc
            name = " " + compName
            
            # If no name is given generate one based on size so that same 
            # size unnamed object get grouped together.
            if name == " "
              name = "noname"
            end 

            materialClass = c.material
            if materialClass == nil
              material = getMaterial(c)
            else
              material = materialClass.name
            end

            # Compare the "sheet" words entered by the user against the 
            # material name. 
            # 
            # If there is a match then this selected entity 
            # becomes a sheet good object.
            # 
            # Everything else is a solid part.
            if isPartOrSheet(@@options[:cutlist_Options][:sheetWords], material) || isPartOrSheet(@@options[:cutlist_Options][:sheetWords], name)
              sheetPart = SheetPart.new(c, name, subAssemblyName, material, 
                                        @volumeMeasureInMetric)
              # Add it to the sheet parts list.
              @sheetPartList.add(sheetPart)
            else
              solidPart = SolidPart.new(c,
                                        name, 
                                        subAssemblyName, 
                                        material, 
                                        @@options[:layout_Options][:nominalMargin], 
                                        @quarter,
                                        @@options[:layout_Options][:nominalOut], 
                                        @volumeMeasureInMetric)
              # Add it to the solid parts list.
              @solidPartList.add( solidPart )
            end
          else
            puts "Skipping partname '" + compName.to_s + "' (level:" + level.to_s  + ", since level=" + (level + 1).to_s + ", has subcomponents)." if $verboseComponentDiscovery
          end
          
          # If the level below had no sub-components, then we just add this 
          # part at this level, so mark this level as having components.
          # 
          # If the level below us had subcomponents, then so must this one 
          # by transitiveness, even if none specifically existed at this level 
          # (there could be nested top level components), so in either case we 
          # set the level to have components.
          levelHasComponents = true
          
        end
      end
    end
    
    puts "returning levelHasSubcomponents=" + levelHasComponents.to_s + " for level=" + level.to_s if $verboseComponentDiscovery
    
    return levelHasComponents
    
  end
  
  # REMOVE:
  def getGroupCopyName(entity)
    name = ""
    definitions = Sketchup.active_model.definitions
    definitions.each { |definition|
      definition.instances.each { |instance|
        
        if instance.typename == "Group" && instance == entity
          # Now go through this definition and see if there is an instance 
          # with a name, return it if found.
          definition.instances.each { |i|
            
            if i.name != ""
              name = i.name
              # Now let's do it again but actually set the name of all 
              # instances to the one found if user OKs this.
              if @askFirstTime
                if UI.messagebox("Copied group parts found with no name. Ok to set to the same name as the master copy?",  MB_OKCANCEL) == 1
                  @okToCopyName = true
                else
                  @okToCopyName = false
                end
                @askFirstTime = false
              end
              if @okToCopyName
                definition.instances.each { |i| i.name = name }
              end
              break
            end
            
          }
          
          return name
          
        end
        
      }
    }
    
    return name
    
  end
  
  def empty?
    
    @parts.length == 0
    
  end
  
end


class Part
  
  def initialize(entity, sub_assembly_name, part_name, material, is_sheet, is_solid, is_hardware)
    
    @sub_assembly = sub_assembly_name
    @part_name = part_name
    @material = material
    @is_sheet = is_sheet
    @is_solid = is_solid
    @is_hardware = is_hardware
        
    # Find the bounding box for the part.
    boundingBox = entity.bounds
    
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
    
    # Get the sorted dimensions
    sizes = get_sorted_array([width, height, depth])
    
    # Assuming the longest dimension is the length and shortest is the thickness
    @thickness = sizes[0]
    @width = sizes[1]
    @length = sizes[2]
    
    # Calculate the dimensions of the part.
    dimension_calculations()
    
    puts "[Part.initialize] @sub_assembly: #{@sub_assembly}" if $debug
    puts "[Part.initialize] @part_name: #{@part_name}" if $debug
    puts "[Part.initialize] @material: #{@material}" if $debug
    puts "[Part.initialize] @thickness: #{@thickness}" if $debug
    puts "[Part.initialize] @width: #{@width}" if $debug
    puts "[Part.initialize] @length: #{@length}\n\n" if $debug
    
    
    # @lengthInFeet = @length.to_feet
    # @material = material
    # @name = strip(name, @length.to_s, @width.to_s, @thickness.to_s )
    # @subAssemblyName = strip(subAssemblyName, @length.to_s, @width.to_s, @thickness.to_s )
    # @canRotate = true
    # @metricVolume = metricVolume
    # @metric = metricModel?
    # @locationOnBoard = nil
    
  end

  def dimension_calculations

    @area = @length * @width
    @volume = @area * @thickness
    @square_feet = @area / 144
    @board_feet = @volume / 144

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

  # def typename
  #   
  #   'foobar'
  #   
  # end

  def sub_assembly
    
    # If there is a sub_assembly_name, than use that, else show "N/A".
    @sub_assembly ? @sub_assembly : 'N/A'
    
  end
  
  def part_name
    
    # If there is a part_name, show that, or else show `N/A'.
    @part_name ? @part_name : 'N/A'
    
  end
  
  def quantity
    
    # TODO: Calculate quantities...
    '1'
    
  end
  
  def width
    
    @width
    
  end
  
  def length
    
    @length
    
  end
  
  def thickness
    
    @thickness
    
  end
  
  def material
    
    @material
    
  end
  
  def area
    
    @area.to_s
    
  end
  
  def volume
    
    @volume.to_s
    
  end
  
  def square_feet
    
    @square_feet.to_s
    
  end
  
  def board_feet
    
    @board_feet.to_s
    
  end

  # Checks to see if a part is a sheet. Returns true if it is, false if not.
  def is_sheet
    
    puts "[Part.is_sheet]: true\n\n" if $debug
    
    @is_sheet
    # is_sheet = false
    #     
    #     # Do a case-insensitive search on all the sheet materials to see if the 
    #     # material matches.
    #     @sheet_materials.each { |m|
    #       
    #       if m.index(/#{@material}/i) != nil
    #         
    #         is_sheet = true
    #         
    #       end
    #       
    #     }
    #     
    #     puts "[Part.is_sheet]: (#{@material}) #{is_sheet}" if $debug
    #     
    #     is_sheet
    
  end
  
  # Checks to see if a part is a solid. Returns true if it is, false if not.
  def is_solid
    
    puts "[Part.is_solid]: true\n\n" if $debug
    
    @is_solid
    
    # is_solid = false
    #     
    #     # Do a case-insensitive search on all the sheet materials to see if the 
    #     # material matches.
    #     @solid_materials.each { |m|
    #       
    #       if m.index(/#{@material}/i) != nil
    #         
    #         is_solid = true
    #         
    #       end
    #       
    #     }
    #     
    #     puts "[Part.is_solid]: (#{@material}) #{is_solid}" if $debug
    #     
    #     is_solid
    
  end
  
  # Checks to see if a part is hardware. Returns true if it is, false if not.
  def is_hardware
    
    puts "[Part.is_hardware]: true\n\n" if $debug
    
    @is_hardware
    
    # # If the part is not a sheet or a solid, than it is assumed to be hardware.
    #     is_hardware = is_sheet && is_solid ? false : true
    #     
    #     puts "[Part.is_hardware]: (#{@material}) #{is_hardware}" if $debug
    #     
    #     is_hardware
    
  end
  
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
