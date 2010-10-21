#-----------------------------------------------------------------------------
# module PartsIntelligence
# Used to answer any questions we may have about the partslist and
# any board options which may help us in selecting boards, making or layout
# optimising the layout or maybe even determining that the layout is not possible
#-----------------------------------------------------------------------------
module PartsIntelligence
  # various reasons why layout will not converge or is impossible
  def layoutImpossible?
    return true if @inPartList.empty?
    return true if !@homerDepot.boardsAvailable?
  end
  # some queries about the partslist which will help us decide
  # how to lay it out
  def allPartsSameThickness?
    @inPartList.allPartsSameThickness?
  end
  def allPartsSameMaterial?
    @inPartList.allPartsSameMaterial?
  end
  # do I have any parts which are wider than the available boards?
  def partsWiderThanBoards?
    @widestBoard = @homerDepot.widestBoardAvailable?
    puts "widest Board Available=" + @widestBoard.to_s if $verbose1
    partArray = @inPartList.getList
    partArray.each { |part| return true if part.getWidth > @widestBoard }
    return false
  end
  
  # do I have parts which are currently thicker than the thickest boards available?
  def partsThickerThanBoards?
    @thickestBoard = @homerDepot.thickestBoardAvailable?.inch
    puts "thickest Board Available=" + @thickestBoard.to_s if $verbose1
    partArray = @inPartList.getList
    partArray.each { |part| return true if part.getThickness > @thickestBoard }
    return false
  end
  
  # do I have parts which require thicker boards than what is available?
  def partsThinnerThanBoards?
    @thickestBoard = @homerDepot.thickestBoardAvailable?.inch
    partArray = @inPartList.getList
    partArray.each { |part| return true if part.getThickness < @thickestBoard }
    return false
  end
  
  # are many parts a multiple of the width of one of the baords
  # if so, then return that width and we'll prefer this size board for layout
  # after splitting the parts into mutiple sections
  def partsMutipleofWidth?
  end
  # determines if complete layout is not possible if the sq footage of the parts
  # exceeds the available boards
  def morePartsThanBoards?
    return false
  end
end

#-----------------------------------------------------------------------------
# The LayoutPreParser takes the parts list and the options and organizes
# the parts by material and thickness, ready for layout
#-----------------------------------------------------------------------------
class LayoutPreParser
  # add mixin module to answer any questions we may have which will help us place
  # the parts
  include PartsIntelligence
  
  def initialize(partsList, inBoardList, partOptions,layoutOptions,metricVolume)
    @homerDepot = BoardSuperMarket.new(inBoardList, partOptions,metricVolume)
    @layoutOptions = layoutOptions
    @layoutByMaterial = layoutOptions[:layoutByMaterial] 
    @quarters = partOptions[2].include? true
    @listOfPartsLists = Array.new()
    @listOfPartsLists.push(partsList)
    @inPartList = partsList
    @status = LayoutStatus.new("","success")
    @partsIgnoreList = CutListPartList.new()
  end
  
  # The preParser makes use of the intelligence module which is a series
  # of methods to answer various questions which may assist in the decision
  # making to better or faster the decision making process and therefore
  # a convergence to an optimal layout (as optimal as the rules we have coded allow for
  # of course)
  def partsPreParser
    puts "partsPreParser:Looking for splits needed..."
    if layoutImpossible?
      @status.set("No parts or no boards.\nLayout is not possible","error")
      return
    end
    if morePartsThanBoards?
      @status.set("Parts exceeds available boards.\nLayout is not possible","error")
      return
    end
    # if no quarters options were given, then skip this step and keep all parts thicknesses as originally created
    # otherwise split any parts up which are thicker than the given board sizes and make them fit on these thicknesses
    if ( partsThickerThanBoards? || partsThinnerThanBoards? )&& @quarters
      # I can lay these out only if you have given me permission to split these into glue-ups
      if @layoutOptions[:splitThickParts]
        # First adjust parts which are still thinner than the thickest board
        # This can occur if the margin specified by the user  + part thickness exceeded the available board thicknesses
        # in this case the part thickness was left unchanged, but since for layout we are allowed to split the parts
        # we can just make the part as thick as it needs to be and let the next step split it if necessary
        normalizeThinGlueUpParts(@thickestBoard)
        # This next step now takes parts thicker than the thickest board
        normalizeGlueUpParts(@thickestBoard)
      else
        @status.set("Some parts require thicker boards than is available.\n" + \
                          "Either check the 'Split Thick Parts' option or specify" + \
                          " thicker boards\n" + \
                          "Some or all of the parts will not be layed out","warning")
        removeThickParts(@thickestBoard)
      end
    end
    if !allPartsSameMaterial?
      # we'll have to split into multiple lists and get different boards for each list
      # we actually make this decision later
    end
    if partsWiderThanBoards?
      # we'll have to split the parts up to lay them out on the available boards
      # split parts up based on the widest board available. 
      # Note this may be a simplistic decision if there are real boards but only some wides ones and 
      # splitting it up this way may still result in the parts not being placed. 
      # Since our list of parts and boards are sorted from largest to smallest, the hope is that we'll find a spot for them all
      # If not, then our todo list will contain boards not placed. It may turn out that splitting the boards in a different fashion
      # would have made them fit, but this is much more difficult decision to make here, so we will leave that to a future version
      # I suppose some sort of adaptive method must be used. If too many parts left over, try a different decision and start again
      # and return the best of the tries  - an interesting problem to solve!
      
      normalizePartsList(@widestBoard) if @layoutOptions[:splitWideParts]
    end
  end
  
  def removeThickParts(thickestBoard)
    partArray = @inPartList.getList
    removalList = Array.new
    partArray.each { |part| 
      if part.getThickness.inch > thickestBoard.inch
        removalList.push(part)
      end
    }
    #now adjust the parts lists - move from main part list to ignore list
    removalList.each{ |oldPart| 
      @inPartList.remove(oldPart)
      @partsIgnoreList.add(oldPart)
     }
end

  # This will split parts which are too thick into as many pieces of the given thickness required to glue-up this part
  # Limit the number of pieces. Anything that has more than say 10 glue ups will be ignored
  def normalizeGlueUpParts(thickestBoard)
    partArray = @inPartList.getList
    removalList = Array.new
    addList = Array.new
    partArray.each { |part| 
      #puts "part=" + part.getName + " index=" + partArray.index(part).to_s
      if part.getThickness.inch > thickestBoard.inch
        # need to figure out how many chunks to split it into
        splitInto = (part.getThickness.inch/thickestBoard.inch).ceil
        if splitInto >= 10
          # this piece is too big for us, reject it
          @status.set("Part " + "'" + part.getName + "'" + " is too thick" + "\nThis part will not be split and will be ignored in the layout ","warning")
          removalList.push(part)
          @partsIgnoreList.add(part)
          next
        end
        # The thickness of each part will always be the thickness of the board
        splitThickness = thickestBoard.inch
        puts "part=" + part.getName + " thickness=" + part.getThickness.inch.to_s + " splits=" + splitInto.to_s + "new thickness=" + splitThickness.to_s if $verbose1
        #make a copy(ies) of this part
        splitInto.times do |i| 
          splitPart = part.deep_clone
          splitPart.changeThickness(splitThickness)
          # add the clones to the list
          addList.push(splitPart)
        end
        # mark the original part for removal from the list, it has been replaced with the split parts. Removing it will also adjust the database and delete this thickness bucket
        # if no longer required
        # Note: removing things from the array while traversing it messes up the indices and therefore causes each to skip some entries
        removalList.push(part)
      end
    }
    #now remove the ones marked for deletion
    removalList.each{ |oldPart| @inPartList.remove(oldPart) }
    #add the new parts created
    addList.each{ |newPart| @inPartList.add(newPart)}
    # sort the list again
    @inPartList.sort
    puts @inPartList.inspect if $verbose
 
  end
  
  # This will restore parts to marginal thickness if marginal thickness was too thick for the available
  # boarrd ( and therefore it was left as is ). We do this because we can split this into glueUps when laying out.
  def normalizeThinGlueUpParts(thickestBoard)
    partArray = @inPartList.getList
    removalList = Array.new
    addList = Array.new
    partArray.each { |part| 
      if part.getThickness.inch < thickestBoard.inch
        puts "thin part=" + part.getName.to_s + " Adjust from" +  part.getThicknessString + " to" + part.getMarginThickness.to_l.to_s
        # just adjust this part thickness back to the marginalThickness
        removalList.push(part)
        newPart = part.deep_clone
        newPart.changeThickness(part.getMarginThickness)
        addList.push(newPart)
      end
    }
    #now remove the ones marked for deletion
    removalList.each{ |oldPart| @inPartList.remove(oldPart) }
    #add the new parts created
    addList.each{ |newPart| @inPartList.add(newPart)}
    # sort the list again
    @inPartList.sort
    puts @inPartList.inspect if $verbose
  end
  
  # This will split any parts which are too wide into some multiple of evenly split widths, no wider than the widest board
  # The parts list will be added to in this method and then re-sorted at the end.
  def normalizePartsList(widestBoard)
    partArray = @inPartList.getList
    removalList = Array.new
    addList = Array.new
    partArray.each { |part| 
      if part.getWidth.inch> widestBoard.inch
          # need to figure out how many chunks to split it into
          splitInto = (part.getWidth.inch/widestBoard.inch).ceil
          splitWidth = widestBoard.inch
          puts "part=" + part.getName.to_s + " width=" + part.getWidth.to_s + " splits=" + splitInto.to_s + " new width=" + splitWidth.to_s if $verbose1
          # change the width of the original
          #make a copy(ies) of this part, 1 less than the number of splits
          splitInto.times do |i| 
            splitPart = part.deep_clone
            splitPart.changeWidth(splitWidth)
            # add the clones to the list
            addList.push(splitPart)
          end
          # mark the original part for removal from the list, it has been replaced with the split parts. 
          removalList.push(part)
      end
      }
    #now remove the ones marked for deletion
    removalList.each{ |oldPart| @inPartList.remove(oldPart) }
    #add the new parts created
    addList.each{ |newPart| @inPartList.add(newPart)}
    # sort the list again
    @inPartList.sort
    puts @inPartList.inspect if $verbose
  end
  
  # organize the parts by layout board type, readying for the layout
  def partsSplitter
    if @layoutByMaterial  
        @listOfPartsLists = @inPartList.splitPartsListByThicknessAndMaterial
    else
        @listOfPartsLists = @inPartList.splitPartsListByThickness
    end
  end
  
  def run
    # gather some useful analysis of the parts list so as to make more intelligent choices of which
    # parts to place on which boards or what kind of boards to ask for
    # split wide or too thick pieces into standardized sizes if user has requested this
    partsPreParser()

    return nil if @status.statusNotGood
    
    # split into multiple lists by materials or thickness or both depending on user options
    # one list per layout type ie: all 3/4" parts on Cherry
    partsSplitter()
    
    return nil if @status.statusNotGood
    return @listOfPartsLists, @partsIgnoreList
  end
end

class SolidPartPreParser < LayoutPreParser
end

class SheetPartPreParser < LayoutPreParser
end

#-----------------------------------------------------------------------------
# class LayoutEngine is the base class for all variants of layout algorithms
#-----------------------------------------------------------------------------
class LayoutEngine  
  # add mixin module to answer any questions we may have which will help us place
  # the parts
  include PartsIntelligence
  
  def initialize(inPartList, inBoardList, boardOptions,layoutOptions,metricVolume)
    # create the perfect store - has only the parts we need :)
    @homerDepot = BoardSuperMarket.new(inBoardList, boardOptions,metricVolume)
    @inPartList = inPartList
    # sort this list
    @inPartList.sort
    #make a copy in case we need to do a do-over
    @originalInPartList = inPartList.deep_clone
    @inBoardList = inBoardList
    @metricVolume = metricVolume
    # create array of boards used to create the cutlist parts assigned to them
    @layoutBoards = Array.new
    @status = LayoutStatus.new("","success")
    @partsToDoList = CutListPartList.new()
    @partsIgnoreList = CutListPartList.new()
    @convergenceImpossible = false
    @layoutOptions = layoutOptions
    @quarters = boardOptions[2]
    @thicknessOptions = (@quarters.include? true )
    #puts "board options=" + @thicknessOptions.to_s
  end

  def convergenceImpossible?
     return @convergenceImpossible == true
  end
    
  def getBoard
    # determine the material and thickness we should be using for this placement
    #if @thicknessOptions
      thickness = @inPartList.getList[0].getThickness 
    #else
      # default thickness
      #thickness=3/4.inch
    #end
    
    # get a board with these properties
    if @layoutOptions[:layoutByMaterial]
      material = @inPartList.getList[0].getMaterial
    else
      material = "generic"
    end
    # get a board from the warehouse
    @board = @homerDepot.getBoard(material, thickness)
    puts "Retrieved board from warehouse:" + @board.to_s if $verbosePartPlacement
    return @board
  end
  
  def placeParts
    puts "-----------------------------------------------------" if $verbosePartPlacement
    puts "placeParts" if $verbosePartPlacement
    @remainingPartsToPlace = @inPartList.count
    puts "parts to place=" + @remainingPartsToPlace.to_s if $verbosePartPlacement
    #now get a board with the options specified
    board = getBoard()
    
    #board = getBoard()
    if board != nil
      # make a new layout board using the baord as the basis
      layoutBoard = LayoutBoard.new(board,@layoutOptions,@metricVolume)
      @layoutBoards.push(layoutBoard)
      # remove a part from the list and place it. Stop when no more parts
      while !@inPartList.empty?
        #just remove the parts one at a time for now
        nextPart = @inPartList.removeFirst!
        # place the part on the board
        if ( layoutBoard.addPartToBoard(nextPart) == false )
          #put the part on a todo list?
          puts "part did not fit" if $verbosePartPlacement
          @partsToDoList.add(nextPart)
        else
          puts "Part placed: " + nextPart.to_s if $verbosePartPlacement
        end
      end
      
      # now switch the todo list and the inPartsList for the next go
      tempListPtr = @inPartList
      @inPartList = @partsToDoList
      @partsToDoList = tempListPtr
      
      #sort the list again
      @inPartList.sort
      #@partsToDoList.sort
      
      # check to see if we are not in a loop because of non-convergence
      # non-convergence here means that a new board has not resulted in any more placed parts -meaning that there is nothing more
      # we can do, so we must stop
      puts "parts left to place=" +  @inPartList.count.to_s if $verbosePartPlacement
      if @remainingPartsToPlace == @inPartList.count
        # we have not made any progress with a new board - must end this foolishness
        @status.set("Some parts were left which could not be placed on given stock.\nTry larger sizes.","warning")
        @convergenceImpossible = true
        puts "Convergence impossible - remaining parts count has not decremented with a new board" if $verbosePartPlacement
        # Nothing was added to this board so remove it from our list
        puts "returning last board to warehouse" if $verbosePartPlacement
        @layoutBoards.pop()
        return
      else
        # this board is full because we've tried every part and no more parts fit but we know we added some
        puts "Board complete or full" if $verbosePartPlacement
        puts "-----------------------------------------------------" if $verbosePartPlacement
        layoutBoard.setBoardFull
      end      
    end
  end
        
  def run
    
    # keep placing parts until we run out of available boards or there are no more parts
    # to place or there is no more convergence ie: we can't place any more parts regardless of having more boards
    while (@homerDepot.boardsAvailable? && !@inPartList.empty? && !convergenceImpossible?)
      placeParts
      return nil if @status.statusNotGood
      puts  "boards?=" + @homerDepot.boardsAvailable?.to_s + \
            " moreParts?=" + (!@inPartList.empty?).to_s + \
            " converging?=" + (!@convergenceImpossible).to_s if $verbosePartPlacement 
    end
          
    #if we still have parts to place but no boards left then tell the user
    if (!@homerDepot.boardsAvailable? && !@inPartList.empty?)
      @status.set("Some parts were left which could not be placed.\nNo boards left or board limit reached.","warning")
    end
      
    return nil if @status.statusNotGood
        
    # return the result of all our work, a list of layoutBoards, each of which contains the parts
    # to be cut out of them and the list of any parts which could not placed
    puts "returning boards=" + @layoutBoards.size.to_s + "Parts leftover=" + @inPartList.count.to_s if $verbosePartPlacement
    return nil, @inPartList if @layoutBoards.empty?
    return @layoutBoards, @inPartList
  end
end

# There's no real difference betwen the layout engines for solid parts vs sheet goods
# the inBoardList and boardOptions may be different and obviously the parts to place
# are different. Our flavour of layout engine is based mainly on the algorithm used.
class BestFitLayoutEngine < LayoutEngine
end

