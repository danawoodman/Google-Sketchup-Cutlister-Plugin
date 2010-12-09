class PartList
  
  def initialize(model, selection)
    
    @model = model
    @selection = selection
    
    # Go through and collect all the parts in the selection.
    @parts = get_parts()
    
  end

  def sheets

    # TODO: Filter out all parts that are not sheets.
    @parts

  end
  
  def solids
    
    # TODO: Filter out all parts that are not solids.
    @parts
    
  end

  def hardware

    # TODO: Return every part that isn't a sheet or solid.
    @parts

  end
  
  def all
    
    @parts
    
  end
  
  # Returns a list of parts, grouping similar parts (e.g. duplicate parts...)
  def get_grouped_parts
    
    # TODO: Write logic for this method...
    
  end
  
  # Looks into the model, gets all the parts and outputs them into an array
  # of part instances.
  def get_parts
    
    array = []
    
    # Collect all the parts that are components or groups and add them to `array`.
    @selection.collect { |s| 
      
      if s.typename == "ComponentInstance" || s.typename == "Group"
        
        array << Part.new(s)
        
      end
      
    }
    
    puts "[PartList] array:" if $debug
    
    array.each { |p|
      
      puts "Part: #{p.typename}, #{p.cabinet_name}, #{p.quantity}, #{p.width},  #{p.length}, #{p.thickness}, #{p.material}, #{p.area}, #{p.volume}, #{p.board_feet}, #{p.square_feet}\n" if $debug
      
    }
    
    puts "\n\n" if $debug
    
    array # Returns the array of parts.
    
  end
  
  def empty?
    
    @parts.length == 0
    
  end
  
end


class Part
  
  def initialize(part)
    
    boundingBox = part.bounds
    
    if part.respond_to? "definition"
      
     boundingBox = part.definition.bounds
     
    end
    
    # Get the transformation of the component.
    trans = part.transformation.to_a
    scale_x = Math.sqrt(trans[0]**2 + trans[1]**2 + trans[2]**2)
    scale_y = Math.sqrt(trans[4]**2 + trans[5]**2 + trans[6]**2)
    scale_z = Math.sqrt(trans[8]**2 + trans[9]**2 + trans[10]**2)    
    
    # Get the width, height and depth of the part.
    width = boundingBox.width * scale_x
    height = boundingBox.height * scale_y
    depth = boundingBox.depth * scale_z
    
    # Get the sorted dimensions
    sizes = get_sorted_array([width, height, depth])
    
    # TODO: Needs to check if these methods have values...
    @name = part.name
    @material = part.material
    
    # Assume the longest dimension is the length and shortest is the thickness
    @thickness = sizes[0]
    @width = sizes[1]
    @length = sizes[2]
    # @lengthInFeet = @length.to_feet
    
    # Calculate the dimensions of the part.
    dimension_calculations()
    
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

  def typename
    
    # TODO: Return the part type: sheet, solid, hardware
    'foobar'
    
  end

  def cabinet_name
    
    # TODO: Get cabinet number/name...
    'foobar cabinet'
    
  end
  
  def part_name
    
    @name
    
  end
  
  def quantity
    
    # TODO: Calculate quantities...
    '1'
    
  end
  
  def width
    
    @width.to_s
    
  end
  
  def length
    
    @length.to_s
    
  end
  
  def thickness
    
    @thickness.to_s
    
  end
  
  def material
    
    # If the part has a material...
    if @material != nil
      
      @material.display_name
    
    # If it has no material...
    else
      
      'N/A'
      
    end
    
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
  
end


# This class represents sheet goods.
# 
# Sheet goods usually represent items such as plywood, MDF, or anything that 
# is in the form of a sheet. The plug-in interprets anything in your 
# "Sheet Goods" list as a sheet part.
# 
# We need to calculate the square footage of sheets because that is the 
# common unit of measure.
class SheetGood < Part
  
end


# This class represents a part of solid stock.
# 
# Solid stock usually represents boards of lumber such as planks. The plug-in 
# interprets anything in your "Solid Stock" list as a solid part.
# 
# We need to calculate the board feet of solid stock because that is the 
# common unit of measure.
class SolidStock < Part
  
end


# This class represents a hardware part.
# 
# Hardware is basically anything other than a sheet good or solid stock. It
# usually represents things like door hinges, handles, drawer slides and the 
# like but could represent anything that has not been defined in the sheet 
# good or solid stock list of keywords.
# 
# We need to calculate the number of hardware parts because that is the only 
# logical way to measure a collection of hardware because hardware could be 
# anything.
# 
# If you find a part that is getting classified as hardware that should be 
# solid stock or sheet goods, make sure it has a material applied to it and 
# that tha material is in either the sheet good or solid part lists in the UI.
class Hardware < Part
  
end
