#-----------------------------------------------------------------------------
# Class PartList - holds all selected components which are neither a 
# solid part nor a sheet part - typically this would be hardware...or bryce
#-----------------------------------------------------------------------------
class PartList

  ### Constructor
  def initialize()
    @parts = Array.new
    @partCount = Array.new
  end  ### Constructor

  def parts
    @parts
  end ###def parts

  def partCount
    @partCount
  end ###def partCount

  ### Adds a part to the list.
  def add(inPart)
    index = @parts.index(inPart)
    if(index != nil)
      @partCount[index] = @partCount[index] + 1
    else
      @parts.push(inPart)
      @partCount.push(1)
    end  ###if
  end ###def add
  
  def empty?
    @parts.length == 0
  end
  
  def getList
    @parts
  end

end ###Class PartList

#-----------------------------------------------------------------------------
# cutlist  base class - represent all cutlist parts of the model, be they solid or sheet
# All lengths are stored in sketchup's default inches unless the name says otherwise
#-----------------------------------------------------------------------------
class CutListPart
  def initialize(c, name, subAssemblyName, material,metricVolume)
    # always get the bounding box from the definition
    # note that we have extended the Sketchup Group class
    # so that we can get the bounding box the same way 
    # whether the entity is a component or a group
    boundingBox = c.bounds
    if c.respond_to? "definition"
     boundingBox = c.definition.bounds
    end
    # get the transformation of the component
    trans=c.transformation.to_a
    scalex=Math.sqrt(trans[0]**2+trans[1]**2+trans[2]**2)
    scaley=Math.sqrt(trans[4]**2+trans[5]**2+trans[6]**2)
    scalez=Math.sqrt(trans[8]**2+trans[9]**2+trans[10]**2)    
    #puts "name=" + name.to_s + "scalex=" + scalex.to_s + " scaley=" + scaley.to_s + " scalez=" + scalez.to_s
    
    width = boundingBox.width*scalex
    height = boundingBox.height*scaley
    depth = boundingBox.depth*scalez
    
    #puts "width=" + width.to_s + " height=" + height.to_s + " depth=" + depth.to_s
    
    #sizes = getSortedArray([boundingBox.width,boundingBox.height,boundingBox.depth])
    sizes = getSortedArray([width,height,depth])
    
    #assume the longest dimension is the length and shortest is the thickness
    @length = sizes[2].inch
    @lengthInFeet = @length.to_feet
    @width = sizes[1].inch
    @thickness = sizes[0].inch
    dimCalculations()
    @material = material
    @name = strip(name,@length.to_s, @width.to_s, @thickness.to_s )
    @subAssemblyName = strip(subAssemblyName, @length.to_s, @width.to_s, @thickness.to_s )
    @canRotate = true
    @metricVolume = metricVolume
    @metric = metricModel?
    @locationOnBoard = nil
  end
  
  def dimCalculations
    @area = @length*@width
    @volume = @area*@thickness
    @squareFeet = @area/144
    @boardFeet = @volume/144
    # part in pixels scale  12in=100px
    # Useful for display purpose but not accurate enough for part comparisans
    @length_px = ((@length/12)*100).to_f.round_to(0)
    @width_px = ((@width/12)*100).to_f.round_to(0)
  end
  
  # Bubble sort
  # sorts in ascending order
  def getSortedArray(array)
    size = array.size()
    pass = size
    for i in (0..pass-2)
      for j in (0..pass-2)
        if (array[j+1] < array[j])
          tmp = array[j]
          array[j] = array[j+1]
          array[j+1] = tmp
        end
      end
    end
    return array
  end

  # used to make the name unique if no name was
  # given to it. The new name is based on the "noname_" + the 
  #concatenation of the dimensions of the part. This allows us
  # to identify identical parts even if they have no name.
  # The order of the dimensions is arbitrary as long as
  # it is consistent but typically same order as the output
  # ie: length, width, thickness
  def strip(name,inV1,inV2,inV3)
    val=name
    if(name=="noname")
      val=("noname_"+inV1+inV2+inV3)
      val = val.gsub(/[ ]/, "_")
      val = val.gsub(/['~"]/, "")
      val = val.gsub(/[\/]/, "-")
    end ## end if
    return val
  end  ## end strip


  #display length or total length of all similar parts
  # is controlled by the 'metricVolume' attribute
  # aka c[6]
  def getTotalLength
    if @metricVolume
      # 1 ft = 0.3048 metres
      (@lengthInFeet*0.3048).round_to(4)
    else
      @lengthInFeet.round_to(2)
    end
  end
  
  # Note: to_l converts inches to Length class, which then prints
  # in whatever units the model is set to
  
  #aka c[1] part length in model units
  def getLengthString
      @length.to_l.to_s
  end
  
  #aka c[2]
  def getWidthString
      @width.to_l.to_s
  end
    
  def getWidth
      @width
  end
    
  def getLength
    @length
  end
    
  #aka c[3]
  def getThicknessString
      @thickness.to_l.to_s
  end

  def getThickness
    @thickness
  end

  #aka c[5] 
  def getMaterial
    @material
  end
  
  #aka c[0]
  def getName
    @name
  end
  
  def getSubAssemblyName
    @subAssemblyName
  end
  
  #aka c[4] for solid parts 
  def getBoardFeet
    if @metricVolume
      #1 mm = 0.0393700787 inches
      # 1 in = 25.40000002590800002642610026955 mm
      # 1bd ft = 144 cu in
      # 1bd ft = 2359.7372232207958956904236222001 cu cm
      # divide by 1000000 to get cu.m.
      #(@boardFeet*2359.7424).round_to(6)
      #(@width.to_l*@length.to_l*@thickness.to_l*2359.7383).round_to(6)
      (@boardFeet*(2359.7372232207958956904236222001/1000000)).round_to(6)
    else
      @boardFeet.round_to(2)
    end
  end
  
  def getBoardFeetLabel
    if @metricVolume
      return "Cubic m"
    else
      return "Board Feet"
    end
  end
  
  # aka c[4] for sheet parts
  def getSquareFeet
    if @metricVolume
      # 1sq ft = 929.0304sq cm
      # divide by 10000 to get sq m
      (@squareFeet*(0.092903040189522201889968968842358)).round_to(6)
    else
      @squareFeet.round_to(2)
    end
  end
  
  def getCanRotate
    @canRotate
  end
  
  def getLengthPx
    @length_px
  end
  
  def getWidthPx
    @width_px
  end
  def addLocationOnBoard(coords)
    # top left coordinate of the location of the part on the board
    # stored in standard dimension units ( ie: everything is relative to the actual size of the board)
    @locationOnBoard = coords
  end
  def getLocationOnBoard
    # return standard dimennsion units ( ie: everything is relative to the actual size of the board)
    @locationOnBoard
  end
  def getLocationOnBoardInPx
    # return top left coordinate (x,y) of the part's location on the board for drawing purposes
    # convert the standard dimension units expressed to Px ( 100px/inch)
    Array[((@locationOnBoard[0]/12)*100).to_f.round_to(0), ((@locationOnBoard[1]/12)*100).to_f.round_to(0)]
  end
  def changeWidth(width)
    @width = width.inch
    dimCalculations()
  end
  def changeThickness(thickness)
    @thickness = thickness.inch
    dimCalculations()
  end
  
  def convertMeasureForCLP(measure)
    # CutList Plus has some import limitations. Inches, feet, mm and cm are
    # accepted but not meters. So here we convert the measure back to a float in inches
    # if the model is in meters. This is just for CutListPlus import file generation
    if modelInMeters?
      measure = measure.to_f.round_to(4)
    end
    return measure      
  end

  def deep_clone  
   Marshal::load(Marshal.dump(self))  
  end 
 
  def summary
    return (getName + " (" + getLengthString + ", " + getWidthString + ", " + getThicknessString + ") " + getMaterial)
  end
end

#-----------------------------------------------------------------------------
# Class SolidPart - to represent all solid parts which are part of the cut list and layout
# Derived from base class CutListPart
#-----------------------------------------------------------------------------
class SolidPart < CutListPart
  
  # initialization for class SolidPart
  # c - sketchup entity, either component or group
  # name - is a string of the name of the entity
  # material - is a string of the material for this entity
  # nominalMargin is a number in 16ths of the allowance required in the thickness over the final part size
  # quarter is an array of 4 elements, being boolean values of fourq, fiveq, sixq and eightq respectively as entered by the user
  def initialize(c, name, subAssemblyName, material, nominalMargin, quarter,nominalOut,metricVolume)
    @nominalMargin = nominalMargin.inch
    @nominalOut = nominalOut
    @quarter = quarter
    super(c,name,subAssemblyName,material,metricVolume)
  end
  
  def dimCalculations
    super
    @nominalThickness = handleNominalSize(@thickness).inch
    @volume = @area*@nominalThickness
    @boardFeet = @volume/144
  end
  
    ## Turn a thickness into a nominal thickness ##
  def handleNominalSize(inThickness)
    result = inThickness
    #keep marginThickness for use later in the layout
    @marginThickness = @nominalMargin+inThickness
    @marginThickness = @marginThickness.round_to(4)
    if((@quarter[0]) && @marginThickness<=1)
      result = 1.inch
    elsif((@quarter[1]) && @marginThickness<=1.25)
      result = (1.25).inch
    elsif((@quarter[2])&& @marginThickness<=1.5)
      result = (1.5).inch
    elsif((@quarter[3]) && @marginThickness<=2)
      result = 2.inch
    elsif((@quarter[4]) && @marginThickness<=2.5)
      result = (2.5).inch
    end #if
    return result
  end ## handleNominalSize
  
  def getThicknessString
    if @nominalOut
      @nominalThickness.to_l.to_s
    else
      @thickness.to_l.to_s
    end
  end
  
  def getMarginThickness
    @marginThickness
  end
  
  def getThickness
    @nominalThickness
  end
  
end

#-----------------------------------------------------------------------------
# Class SheetPart - to represent all components cut from sheet stock 
# and which are part of the cut list and layout. Derived from base class CutListPart
#-----------------------------------------------------------------------------
class SheetPart < CutListPart
  
  # for sheet goods, the board ft measure is actually the square footage
  def getBoardFeet
    getSquareFeet
  end
  
  def getBoardFeetLabel
    if @metricVolume
      return "Square m"
    else
      return "Square feet"
    end
  end

end

#-----------------------------------------------------------------------------
# Base class for all lists of components 
# Maintains a list of all parts which can be sorted by name within length within board feet
# simultaneously maintains a list of parts indexed by [material,thickness]
#-----------------------------------------------------------------------------
class CutListPartList
  # Constructor
  def initialize()
    # array of cut list part objects
    @componentList = Array.new
    @componentListByMaterialAndThickness = Hash.new
  end 
  
  def addToPartDatabase(cutListPart)
    return if cutListPart == nil
    material = cutListPart.getMaterial
    # get thickness and convert to string to use as an index in the hash
    thickness = cutListPart.getThickness.inch.to_s
    #puts " thickness=" +  thickness.to_s
    if !@componentListByMaterialAndThickness.include? material
      # this a new material, create a new entry in the material array
      newThicknessHash = Hash.new
      #puts "new material hash for " + material.to_s
      @componentListByMaterialAndThickness[material] = newThicknessHash
    end
    # If this is a new thickness, create a new parts array and a new hash to this array
    # using this new thickness
    if !@componentListByMaterialAndThickness[material].include? thickness
      #create a new array for the parts at this thickness
      #puts "new thickness hash for " + thickness.to_s + " " + material.to_s
      newPartArray = Array.new
      @componentListByMaterialAndThickness[material][thickness] = newPartArray
    end
    # in any case, add this part
    @componentListByMaterialAndThickness[material][thickness].push( cutListPart )
  end
  
  def removeFromPartDatabase(cutListPart)
    return if cutListPart == nil
    # when removing we must first update the hash list of [material,thickness]
    material = cutListPart.getMaterial
    # get thickness and convert to string to use as an index in the hash
    thickness = cutListPart.getThickness.inch.to_s
    #puts "removing part from material=" + material + " thickness= " + thickness
    #puts @componentListByMaterialAndThickness[material].to_s
    #puts @componentListByMaterialAndThickness[material][thickness].to_s
    @componentListByMaterialAndThickness[material][thickness].delete( cutListPart )
    #remove the thickness hash if now empty
    if @componentListByMaterialAndThickness[material][thickness].empty?
      #remove the thickness hash
      @componentListByMaterialAndThickness[material].delete(thickness)
    end
    #remove the material hash if now empty
    if @componentListByMaterialAndThickness[material].empty?
      #remove the material hash
      @componentListByMaterialAndThickness.delete(material)
    end
  end
  
  # add a cut list object to the array
  def add(cutListPart)
    @componentList.push(cutListPart)
    addToPartDatabase(cutListPart)
  end
  
  def remove(cutListPart)
    removeFromPartDatabase(cutListPart)
    @componentList.delete(cutListPart)
  end
  
  def empty?
    @componentList.length == 0
  end
  
  def count
    @componentList.length
  end
  
  def allPartsSameMaterial?
    return true if @componentList.empty?
    material = @componentList.first.getMaterial
    return ( @componentList.select{|x| x.getMaterial != material } == nil )
  end
  
  def allPartsSameThickness?
    return true if @componentList.empty?
    thickness = @componentList.first.getThickness
    return (@componentList.select{|x| x.getThickness != thickness } == nil )
  end
  
  # returns the list in its current context
  def getList
      return @componentList
  end
  
  def removeFirst!
    #removes the first part in the list (biggest part in a sorted list) and return it.
    # returns nil if the list is empty
    cutListPart = @componentList.shift
    removeFromPartDatabase(cutListPart)
    return cutListPart
  end
  
  def insertFirst!(cutListPart)
    #add a part back to the front of the list
    @componentList.unshift(cutListPart)
    addToPartDatabase(cutListPart)
  end
    
  # sort and return a copy of the list. Does not change the component list 
  def sort
    # sort in descending order of board feet ( which is sq feet for sheets )
    # if board feet of the two parts are the same, then sort by length
    # if length is the same, then sort by name - putting like parts together
    # return the sorted list
    sortedComponentList = @componentList
    size = sortedComponentList.size()
    pass = size
    for i in (0..pass-2)
      for j in (0..pass-2)
        if (sortedComponentList[j].getBoardFeet < sortedComponentList[j+1].getBoardFeet)
          tmp = sortedComponentList[j+1]
          sortedComponentList[j+1] = sortedComponentList[j]
          sortedComponentList[j] = tmp
        elsif (sortedComponentList[j].getBoardFeet == sortedComponentList[j+1].getBoardFeet)
          # if boardfeet is identical, then sort by length
          if (sortedComponentList[j].getTotalLength < sortedComponentList[j+1].getTotalLength )
            tmp = sortedComponentList[j+1]
            sortedComponentList[j+1] = sortedComponentList[j]
            sortedComponentList[j] = tmp
          elsif (sortedComponentList[j].getTotalLength == sortedComponentList[j+1].getTotalLength )
            # if length identical, then sort by name
            if (sortedComponentList[j].getName > sortedComponentList[j+1].getName )
              tmp = sortedComponentList[j+1]
              sortedComponentList[j+1] = sortedComponentList[j]
              sortedComponentList[j] = tmp
            end
          end
        end
      end
    end
    return sortedComponentList
  end
  
  # sort by name and return a copy of the list. Does not change the component list 
  # This sorted view is used so that the compact view lists by component name
  def sortByName
    # sort in descending order by name with no regard to board feet or part length
    # return the sorted list
    sortedComponentList = @componentList
    size = sortedComponentList.size()
    pass = size
    for i in (0..pass-2)
	for j in (0..pass-2)
		if (sortedComponentList[j].getName > sortedComponentList[j+1].getName )
			tmp = sortedComponentList[j+1]
			sortedComponentList[j+1] = sortedComponentList[j]
			sortedComponentList[j] = tmp
		end
	end
    end
  end
  
  # sort and overwrite the list with the sorted list
  def sort!
    sortedList = @componentList.sort
    @componentList = sortedList
  end
  
  def deep_clone  
   Marshal::load(Marshal.dump(self))  
  end 
    
  def splitPartsListByMaterial
    @listOfPartsListsByMaterial = Array.new
    # the default is a single entry in the array with the original partsList if all parts have the same material
    if allPartsSameMaterial?
        @listOfPartsListsByMaterial.push(self)
        return @listOfPartsListsByMaterial 
    end
    # some parts are of a different material. Retrieve those. Each new material gets its own partsList
    # all thicknesses are lumped together
    @componentListByMaterialAndThickness.each{ |material,thickness|
      partListByMaterial = CutListPartList.new
      @componentListByMaterialAndThickness[material].each{ |thickness,part|
        @componentListByMaterialAndThickness[material][thickness].each{ |part|
          partListByMaterial.add(part)
        }
      }
      @listOfPartsListsByMaterial.push(partListByMaterial)
    }
    return @listOfPartsListsByMaterial
  end
      
  def splitPartsListByThicknessAndMaterial
    @listOfPartsListsByMaterialAndThickness = Array.new
    # the default is a single entry in the array with the original partsList if all parts have the same material and thickness
    if allPartsSameMaterial? && allPartsSameThickness?
        @listOfPartsListsByMaterialAndThickness.push(self)
        return @listOfPartsListsByMaterialAndThickness
    end
    # else some parts are of a different material. Retrieve those. Each new combination of material,thickness
    # gets its own list
    @componentListByMaterialAndThickness.each{ |material,thickness|
      @componentListByMaterialAndThickness[material].each{ |thickness,part|
        partListByThicknessAndMaterial = CutListPartList.new
        @componentListByMaterialAndThickness[material][thickness].each{ |part|
          partListByThicknessAndMaterial.add(part)
        }
        @listOfPartsListsByMaterialAndThickness.push(partListByThicknessAndMaterial)
      }
    }
    #puts @listOfPartsListsByMaterialAndThickness.to_s
    return @listOfPartsListsByMaterialAndThickness
  end
  
  def splitPartsListByThickness
    @listOfPartsListsByThickness = Array.new
    if allPartsSameThickness?
        @listOfPartsListsByThickness.push(self)
        return @listOfPartsListsByThickness
    end
    # else some parts are of a different thickness. Retrieve those. Each new thickness regardless of material gets its own list
    # search the database and create a hash by thickness, which is easier to populate, then convert to an array at the end.
    thicknessHash = Hash.new
    @componentListByMaterialAndThickness.each{ |material,thickness|
      @componentListByMaterialAndThickness[material].each{ |thickness,part|
        if !thicknessHash.include? thickness
          puts "List Parts by Thickness: new thickness=" +  thickness
          partListByThickness = CutListPartList.new
          thicknessHash[thickness] = partListByThickness
        end
        @componentListByMaterialAndThickness[material][thickness].each{ |part|
          thicknessHash[thickness].add(part)
        }
      }
    }
    #convert hash to our array
    thicknessHash.each { |thickness,partList| @listOfPartsListsByThickness.push(partList) }
    return @listOfPartsListsByThickness
  end 
  
  def +(cutListPartList)
    # add the parts on the list and return self.
    return if cutListPartList == nil
    cutListPartList.getList.each { |part| add(part) }
  end
  
  
end
  
#-----------------------------------------------------------------------------
# Class SolidPartList - List of all solid component parts which are part 
# of the cut list and layout
#-----------------------------------------------------------------------------
class SolidPartList < CutListPartList
end

#-----------------------------------------------------------------------------
# Class SheetPartList - List of all sheet component parts which are part 
# of the cut list and layout
#-----------------------------------------------------------------------------
class SheetPartList < CutListPartList
end

#-----------------------------------------------------------------------------
# Class BoardList - List of all boards available for the layout where 
# boards have been specified by the user. A list of raw boards.
#-----------------------------------------------------------------------------
class BoardList < CutListPartList
end
