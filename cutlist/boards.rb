#-----------------------------------------------------------------------------
# Class BoardWarehouse is an abstraction of all information about boards or sheet goods 
# which are available to use for the layout.
# These may be actual boards which the user has provided us or it is a 
# description of boards which may be used.
# It manages getting a board closest to your specification either inventing one ( ordering it
# presumable from some sustainably managed pool of electronic boards) or getting one out
# of the warehouse ( which the user has obviously obtained from a sustainable source)
# Boards may be returned for a different size if it didn't suit and substituted for another one
#-----------------------------------------------------------------------------
class BoardWarehouse
  def initialize(metricVolume)
    @boardList =BoardList.new()
    @boardOptions = [[],[],[],false]
    @metricVolume = metricVolume
  end
    
  # accept a request for a board of a specific size and return the best possible choice, either
  # an actual board, or a 'virtual board', on special order. There are unlimited
  # virtual boards in all sizes but a fixed number of actual boards, otherwise
  # once created, they behave the same way
  def boardOrder(length, width)
  end
  
  # didn't like the board? As long as you didn't cut it, we'll take it back
  # real boards are returned to inventory, whereaas virtual boards just cancels
  # the special order ( ie: nothing changes)
  def boardReturn(board)
  end
  
  # this is the generally used interface. Just returns the best next available board
  # Best here means the largest board available
  # returns an instance of class LayoutBoard
  def getBoard
    #find a board
    #create and return a LayoutBoard
  end
  
  def boardsAvailable?
  end
  
  # determine the widest board in the inventory
  def widestBoardAvailable?
  end
  # determine the thickest board in the inventory
  def thickestBoardAvailable?
  end
end

#-----------------------------------------------------------------------------
# A set of methods for real boards defined as module so it can be mixed in as needed
# to our warehouse class
#-----------------------------------------------------------------------------
module RealBoards
  def getRealBoard(material,thickness)
  end
  
  def getSpecificRealBoard(length,width,thickness,material)
  end
  
  # a delivery of real boards, can also be done after initialization
  def realBoardDelivery(boardList)
    @boardList = boardList
  end
  def anyRealBoardsAvailable?
     !@boardList.empty?
   end
   
  # determine the widest board in the inventory
  def widestRealBoardAvailable?
    return 0 if !anyRealBoardsAvailable?
    boardListArray = @boardList.getList
    widest = boardListArray[0].getWidth
    boardListArray.each {|board| 
      width = board.getWidth;
      widest = width if width > widest
      }
    return widest
  end
  # determine the thickest board in the inventory
  def thickestRealBoardAvailable?
    return 0 if !anyRealBoardsAvailable?
    boardListArray = @boardList.getList
    thickest = boardListArray[0].getThickness
    boardListArray.each {|board| 
      thickness = board.getThickness;
      thickest = thickness if thickness > thickest
      }
    return thickest
  end
end

#-----------------------------------------------------------------------------
# A set of methods for virtual boards (only defined as options)
# defined here as a module so it can be mixed in as needed to our warehouse class
#-----------------------------------------------------------------------------
module VirtualBoards
  # We restrict the number of boards in our inventory to 20 boards mainly as a way of ensuring that
  # the layout doesn't take an excessive length of time. We can change this as the performance of the
  # output improves.
  # 2010.06.01 This has now been improved so the ceiling is lifted to a large number
  @@boardLimit = 100
  
  # this method always gets the biggest board possible. If you want a specific board then used
  # getSpecificVirtualBoard
  def getVirtualBoard(material, thickness)
    return nil if !anyVirtualBoardsAvailable?
    # sort legnth and width option arrays
    sortedLength = @boardOptions[0].sort
    sortedWidth = @boardOptions[1].sort
    # get the largest board possible
    longest = sortedLength.last
    widest = sortedWidth.last
    # create a board with these dimensions. 
    # Get the thickness closest to that requested
    newThickness = closestThicknessVirtualBoard(thickness)
    # If nominalWidth asked for,then explicitly get the size requested, otherwise get
    # a dressed board
    if @nominalWidth
      board = Board.new(longest,widest,newThickness,material,@metricVolume)
    else
      board = NominalBoard.new(longest,widest,newThickness,material,@metricVolume)
    end
    # reduce the number of boards in the inventory
    @numberOfBoards -= 1
    return board
  end
  
  # get a board as close to the specification as possible. If nothing is available in the right
  # size, look for the smallest board which is larger. If nothing is larger, get the one which is closest 
  # but smaller. The layout engine will decide if it works or not, we just get what is asked for.
  def getSpecificVirtualBoard(length,width,thickness,material)
    return nil if !anyVirtualBoardsAvailable?
    
    # sort length and width option arrays
    sortedLength = @boardOptions[0].sort
    sortedWidth = @boardOptions[1].sort
    
    #find the closest values in the options table
    closestLength = findClosest(length,sortedLength)
    closestWidth = findClosest(length,sortedWidth)
    
    # wouldn't expect not to find something but just in case
    return nil if (closestWidth == nil || closestLength == nil )
    
    #create a board with these dimensions and return
    if @nominalWidth
      board = Board.new(closestLength,closestWidth,thickness,material,@metricVolume)
    else
      board = NominalBoard.new(closestLength,closestWidth,thickness,material,@metricVolume)
    end
    # reduce the number of boards in the inventory
    @numberOfBoards -= 1
    return board
  end
  
  # takes a number and a sorted array of numbers and finds the entry which is :
  # exactly that number
  # slightly bigger if not exact
  # slightly smaller if nothing bigger or exact
  def findClosest(dimension,optionArray)
    #find all entries larger than or equal to the dimension and pick the first one to return
    largest = optionArray.select{|x| x >= dimension }
    return largest[0] if largest != nil
    #find the one just smaller 
    smallest = optionArray.select{|x| x < dimension }
    return smallest[0] if smallest != nil
    return nil
  end
  
  # delivery via boardOptions methods - can be added after initialization
  def virtualBoardDelivery(boardOptions)
    #not much to do with the options except to store the options
    @boardOptions = boardOptions
    @nominalWidth = boardOptions[3]
    # set number of boards available with this delivery
    @numberOfBoards = @@boardLimit
  end
  
  def anyVirtualBoardsAvailable?
    # have we reached our inventory limit?
    return false if @numberOfBoards == 0
    # if we have any width and length board options, then there are always more boards to be had
    return (!@boardOptions[0].empty? && !@boardOptions[1].empty? )
  end
  
  # determine the widest board in the inventory subject to the user selected option to have undressed boards (nominalWidth)
  def widestVirtualBoardAvailable?
    sortedWidth = @boardOptions[1].sort
    widestBoard = sortedWidth.last
    return widestBoard if @nominalWidth
    return widestBoard -=  1/2.inch  if widestBoard <= 6.inch
    return widestBoard -=  3/4.inch 
  end
  # determine the thickest board in the inventory
  def thickestVirtualBoardAvailable?
    # check which of the "quarter" thickness options has been selected, if any.
    # if none selected, return default of 3/4

    return (2.5).inch if @boardOptions[2][4]
    return 2.inch if @boardOptions[2][3]
    return (1.5).inch if @boardOptions[2][2]
    return (1.25).inch if @boardOptions[2][1]
    return 1.inch if @boardOptions[2][0]
    return 3/4.inch
  end
  
  # find the thickness closest to that requested which is larger
  # if no options set, then return the requested thickness
  def closestThicknessVirtualBoard(thickness)
    return 1.inch if @boardOptions[2][0] && 1.inch >= thickness
    return (1.25).inch if @boardOptions[2][1] && (1.25).inch >= thickness
    return (1.5).inch if @boardOptions[2][2] && (1.5).inch >= thickness
    return 2.inch if @boardOptions[2][3] && (2).inch >= thickness
    return (2.5).inch if @boardOptions[2][4] && (2.5).inch >= thickness
    return thickness
  end
end

# warehouse wth real boards to/from the warehouse
class BoardLumberYard < BoardWarehouse
  
  #include instance methods from the RealBoard module
  include RealBoards
  
  def initialize(boardList,metricVolume)
    super(metricVolume)
    realBoardDelivery(boardList)
  end
  
  def getBoard(material="default", thickness=1.0.inch)
    getRealBoard(material, thickness)
  end
  
  def boardsAvailable?
    anyRealBoardsAvailable?
  end
  
  # determine the widest board in the inventory
  def widestBoardAvailable?
    widestRealBoardAvailable?
  end
  # determine the thickest board in the inventory
  def thickestBoardAvailable?
    thickestRealBoardAvailable?
  end
end

#-----------------------------------------------------------------------------
# warehouse with only board dimension combinations which can be ordered
# ie: it is what the user has specifed using the boardOptions
#-----------------------------------------------------------------------------
class BoardServiceDesk < BoardWarehouse
  
  #include instance methods from the Virtual Board module
  include VirtualBoards

  def initialize(boardOptions,metricVolume)
    super(metricVolume)
    virtualBoardDelivery(boardOptions)
  end
  
  def boardDelivery(boardList,boardOptions)
  end
  
  def getBoard(material="default", thickness=1.0.inch)
    getVirtualBoard(material, thickness)
  end
  
  def boardsAvailable?
    anyVirtualBoardsAvailable?
  end
  # determine the widest board in the inventory
  def widestBoardAvailable?
    widestVirtualBoardAvailable?
  end
  # determine the thickest board in the inventory
  def thickestBoardAvailable?
    thickestVirtualBoardAvailable?
  end
end
#-----------------------------------------------------------------------------
# the full service board warehouse
# Has both real boards, which the user has specified that he/she has
# As well as an unlimited number of boards which can be ordered based on the
# boardOptions specified.
# ( The interface would be something like a list of available boards and
#   then a specification of what size board should make up any shortfall using boardOptions )
#-----------------------------------------------------------------------------
class BoardSuperMarket < BoardWarehouse
  #include instance methods from both the RealBoard module and Virtual Board module
  include RealBoards
  include VirtualBoards
  
  # if you have both options and real boards use this initialization
  def initialize(boardList,boardOptions,metricVolume)
    super(metricVolume)
    realBoardDelivery(boardList)
    virtualBoardDelivery(boardOptions)
  end
  
  def getBoard(material="default", thickness=1.0.inch)
    return getVirtualBoard(material,thickness) if !getRealBoard(material,thickness)
  end
  
  def boardsAvailable?
    return anyVirtualBoardsAvailable? if !anyRealBoardsAvailable?
    return true
  end
  
  def widestBoardAvailable?
    widestRealBoard = widestRealBoardAvailable?
    widestVirtualBoard = widestVirtualBoardAvailable?
    return widestRealBoard if widestRealBoard > widestVirtualBoard
    return widestVirtualBoard
  end
  
  def thickestBoardAvailable?
    thickestRealBoard = thickestRealBoardAvailable?
    thickestVirtualBoard = thickestVirtualBoardAvailable?
    return thickestRealBoard if thickestRealBoard > thickestVirtualBoard
    return thickestVirtualBoard
  end
  
end

#-----------------------------------------------------------------------------
# class Board - raw material from which we can cut the parts
#-----------------------------------------------------------------------------
class Board
  def initialize(length,width,thickness,material,metricVolume)
    # kept internally in inches
    @length = length.inch
    @width = width.inch
    @thickness = thickness.inch
    @material = material
    calcBoardFeet
    
    #store the board size in pixels as well. 100 pixels to the foot
    # as this displays in a reasonable scale.
    # we only need the length and the width
    # width in px represents the actual size of the board
    # Note: This is only an approximation of the true size and is useful for display purpose
    # but not necessarily accurate for comparing for part fit
    # Comparisons for fit are done using as much precision as possible and so the
    # actual board size is used. Using px has the problem of, well, pixelation
    # which takes away accuracy because of its inherent need to subdivide into a
    # unit with poor granularity.
    @length_px = ((@length/12)*100).to_f.round_to(0)
    @width_px = ((@width/12)*100).to_f.round_to(0)
    @area_px = @length_px*@width_px
    @metricVolume = metricVolume
  end
  
  def calcBoardFeet
    @area= @length*@width
    @boardFeet = (@area*@thickness)/144
  end
  
  # print the dimensions of the board
  def to_s
    getWidthString + ' x ' + getLengthString + ', ' + getThicknessString + ' ' + getMaterial + ' ' + getBoardFeetString 
  end
  def getLength
    @length
  end
  def getLengthString
    getLength.to_l.to_s
  end
  def getWidth
    @width
  end
  def getWidthString
    getWidth.to_l.to_s
  end
  def getThickness
    @thickness
  end
  def getThicknessString
    getThickness.to_l.to_s
  end
  def getMaterial
    @material
  end
  def getLengthPx
    @length_px
  end
  def getWidthPx
    @width_px
  end
  def getAreaPx
    @area_px
  end
  def getBoardFeet
    if @metricVolume
      # 1bd ft = 2359.7424/1000000 cu m
      # Use as much accuracy as possible.
      (@boardFeet*(2359.7372232207958956904236222001/1000000)).round_to(4)
    else
      @boardFeet.round_to(2)
    end
  end
  def getRawBoardFeet
    @boardFeet
  end
  def getBoardFeetUnitsString
    return ' cu.m.' if @metricVolume
    return ' bd.ft.' if !@metricVolume
  end
  def getBoardFeetString
    string = getBoardFeet.to_s
    string += getBoardFeetUnitsString
    return string
  end
  
end

#-----------------------------------------------------------------------------
# a nominal board is a board whose actual dimensions are slightly smaller
# than the nominal size ie: 1/2" less when <= 6"  and 3/4" less if > 6"
# board feet is based on the nominal size, not the actual size
# Otherwise everything else about it is the same
# This is the default board we use
#-----------------------------------------------------------------------------
class NominalBoard < Board
  def initialize(length,width,thickness,material,metricVolume)
    @nominalWidth = width.inch
    if @nominalWidth <= 6.inch
      actualWidth = width.inch - 1/2.inch 
    else
      actualWidth = width.inch - 3/4.inch
    end
    super(length,actualWidth,thickness,material,metricVolume)
  end
  def calcBoardFeet
    @area= @length*@nominalWidth
    @boardFeet = (@area*@thickness)/144
  end
  def getWidthString
    return getNominalWidth.to_l.to_s + "(" + getWidth.to_l.to_s + ")"
  end
  def getNominalWidth
    @nominalWidth
  end
end

# used to identify and handle different errors produced by the layout engine
class LayoutStatus
  def initialize(error,type)
    set(error,type)
  end
  def set(error,type)
    @error = error
    @type = type
  end
  def display
    if @type == "fatal"
      UI.beep
      UI.messagebox(@error)
    elsif @type == "error"
      UI.beep
      UI.messagebox(@error)
    elsif @type == "warning"
      UI.beep
      UI.messagebox(@error)
    elsif @type == "choice"
      UI.beep
      UI.messagebox(@error)
    elsif @type == "success"
    end
    #clear the error once displayed
    @error=""
    @type="success"
  end
  def getResultType
    @type
  end
  def good?
    return true if (@type == "" || @type == "success" )
    return false
  end
  def warn?
    return true if (@type == "warning" || @type == "choice" )
    return false
  end
  def stop?
      return true if (@type == "error" || @type == "fatal")
      return false
  end
    
  def statusNotGood
    if good?
      return false
    end
    if warn?
      display
      return false
    end
    if stop?
      display
      return true
    end
    return false
  end
end

#-----------------------------------------------------------------------------
# class LayoutBoard - boards used in the layout - maintains a list of parts
# which are to be cut from this board and the data structure representing 
# used and unused portions of the board.
# Note that this view of the board is specific to this layout algorithm. 
# Other algorithms may need a different LayoutBoardClass
# This is a tree structure. Whenever a part is cut out of the board, the
# remaining area can be represented by two rectangles - two in the horizontal direction
# and two in the vertical direction covering all of the remaining unused space. 
# These two views represent all options for future placement
# and are represented as left and right branches of a tree structure.
# When we go to place the next part, we choose the best option by determining which fills one of
# available spaces the best. When that choice is selected, then we eliminate from the tree the 
# options which are no longer available
# For example, let's say we have a 4x8 sheet of plywood. Place the sheet horizontally.
# if we need a piece cut out 2'x3', then horizontal remaining spaces are 2x5,2x8 ( =10+16=26 sq ft)
# vertical remaining spaces are 3x2 and 5x4 ( =6+20=26bdft)
# As soon as we select one of the 4 choices for the next part, that selects that pair and the pair not chosen
# is immediately eliminated from further choices. Then the part that is placed subdivides the space that we chose
# with 4 options and so on.
# Whenever we go to place a part we explore all available options for one that fits the best ie: with the least amount of waste
# we do this by comparing sq ft of the part to be placed with the sq ft of the available space.
# 
#
#    +------------------+------------------------------------+
#    |                  |                                    |
#    |                  |   2                                |
#    |__________________|                                    |  4
#    |         3                                             |
#    |                                                       |
#    |                                                       |
#    +-------------------------------------------------------+
#                                         8
#-----------------------------------------------------------------------------
  
class LayoutBoard
  class LeafNode
    @@nodeType="leaf"
    def initialize(parent)
      @parent = parent
      @rect = {:xy => Array[0,0], :length => 0, :width => 0 }
    end
    # each leaf node holds a description of the available rectangle on this board
    # This is given by the :xy which is an array of top, left coordinates, relative to 0,0 being at the top left
    # and the :length and :width of the piece 
    def addRect(rect)
      @rect = @rect.merge!(rect)
      # :xy is the(x,y) coordinate of the top left of the part
      # :length is the length
      # :width is the width
    end
    def rect
      @rect
    end
    def getNodeType
      @@nodeType
    end
    def parent
      @parent
    end
  end
  
  class Node
    @@nodeType="node"
    def initialize(parent)
      @parent = parent
      @left = nil
      @right = nil
      @part = {:xy => Array[0,0], :length => 0, :width => 0 }
    end
    # rect is a description of the space available
    # The parameter rect is a description of the size defined as a pair of (x,y) coordinates
    # where (x1,y1) is the top left and (x2,y2) is the bottom right in a coordinate system
    # where (0,0) is at the top left corner, positive x is from left to right and positive y is from top to bottom
    # left always contains the remaining space described in a  horizontal orientation
    def addLeft(rect)
      @left = LeafNode.new(self)
      @left.addRect(rect)
    end
    # right is a description of the space available in vertical oreientation
    # see above for how the parameter rect is expected
    def addRight(rect)
      @right = LeafNode.new(self)
      @right.addRect(rect)
    end
    def left
      @left
    end
    def left=(left)
      @left=left
    end
    def right=(right)
      @right=right
    end
    def right
      @right
    end
    def parent
      @parent
    end
    def getNodeType
      @@nodeType
    end
    def part
      @part
    end
    def addPart(part)
      @part = @part.merge!(part)
    end
    def getPartArea
      return @part[:width]*@part[:length]
    end
  end

  def initialize(board,layoutOptions,metricVolume)
    #super(board.getLength,board.getWidth,board.getThickness,board.getMaterial,metricVolume)
    @board = board
    @layoutOptions = layoutOptions
    # initialize the list of parts which will be cut out of this board
    @partInBoardList = SolidPartList.new()
    # initialise the kerf size if any
    @kerfSize = @layoutOptions[:sawKerfSize] if @layoutOptions[:useSawKerf]
    @kerfSize = 0 if !@layoutOptions[:useSawKerf]
    #debug
    puts "Kerf Size=" + @kerfSize.to_s if $verboseParameters
    
    # intialize the root node
    @root = Node.new(self)
    #initial view is that the entire board is represented on one leaf node, left or right makes no diff at this point
    topLeft = Array[0,0]
    #add a board whhich is kerfSize wider and longer to account for kerfsize being added to the length and width of each part
    # so even if the part is exactly the width of the board requiring no cuts, it will fit
    @root.addLeft( {:xy =>topLeft,:length =>@board.getLength+@kerfSize,:width =>@board.getWidth+@kerfSize} )
    @boardFull = false
  end

  #add a part to be cut out of this board
  #layoutPart is an instance of LayoutPart
  def addPartToBoard(layoutPart)
    # now figure out where it should be placed on the board. Find enough room for the part + kerfsize on one edge of the width and one on the length
    leafNode = findBestFit(@root, layoutPart.getLength+@kerfSize, layoutPart.getWidth+@kerfSize)
    # return if we couldn't fit this part
    return false if leafNode == nil

    # place the locaton info in the parts list as well, against the part it represents.
    layoutPart.addLocationOnBoard(leafNode.rect[:xy])
    
    #add it to our list of parts which are on this board - this is just a list in case we need 
    # quick access later on for display reasons or counting, without having to traverse the tree
    @partInBoardList.add(layoutPart)

    # mark the space used by this part as taken and adjust the tree of available space
    insertPartInTree(leafNode,layoutPart)
    puts "part added!" if $verbose
    return true
  end
  
  def insertPartInTree(leaf,layoutPart)
    # insert this part into the node of our parent
    #leaf.parent.addPart( {:xy => leaf.rect[:xy], :length => layoutPart.getLengthPx, :width => layoutPart.getWidthPx } )
    leaf.parent.addPart( {:xy => leaf.rect[:xy], :length => layoutPart.getLength, :width => layoutPart.getWidth } )
    
    
    #remove the branch not chosen from the parent and link in a new Node on the branch chosen
    # figure out if we are the right or left node and delete the other one - we dont need it anymore cause it wasn't chosen
    if leaf.parent != @root
      if leaf.parent.parent.left == leaf.parent
        leaf.parent.parent.right = nil
      else
        leaf.parent.parent.left = nil
      end
    # else tree is in the degenerative form still - nothing to do
    end
    
    #create a new Parent for the left and right child and its leaves and link it in to our parent. 
    newParent = Node.new(leaf.parent)
    # figure out which side to link this to - depends on where the leaf is 
    if leaf.parent.right == leaf
      leaf.parent.right = newParent
    else
      leaf.parent.left = newParent
    end
    
    # now create a new child to hold the left spaces - link it to the left of our new Parent
    newLeftChild = Node.new(newParent)
    newParent.left = newLeftChild
    
    # and one for the right
    newRightChild = Node.new(newParent)
    newParent.right = newRightChild

    # determine the new origin of the space remaining on the left lower horizontal space
    # left node is the horizontal spaces remaining
    # if width remaining is 0, then we don't need a left node
    #newWidth = leaf.rect[:width] - layoutPart.getWidthPx
    newWidth = leaf.rect[:width] - layoutPart.getWidth
    if newWidth != 0
      # x remains the same since the part is placed in top left corner
      # y is old y + layout part width + kerf size
      newx = leaf.rect[:xy][0]
      #newy = leaf.rect[:xy][1]+layoutPart.getWidthPx
      newy = leaf.rect[:xy][1]+layoutPart.getWidth
      newLength = leaf.rect[:length]
      # create and add a new left node to the node just created
      newOrigin = Array[newx,newy]
      newLeftChild.addLeft({:xy => newOrigin, :length => newLength, :width => newWidth})
    end
    
    # right node is the other horizontal space remaining to the right of the part placed - the upper horizontal space
    #newLength = leaf.rect[:length] - layoutPart.getLengthPx
    newLength = leaf.rect[:length] - layoutPart.getLength
    if newLength != 0
      # y remains the same since the part is placed in the top left corner - this space is immediately to the right of it
      # x is old x + layout part length
      newy = leaf.rect[:xy][1]
      #newx = leaf.rect[:xy][0]+layoutPart.getLengthPx
      newx = leaf.rect[:xy][0]+layoutPart.getLength
      #newWidth = layoutPart.getWidthPx
      newWidth = layoutPart.getWidth
      # create and add a new left node to the node just created
      newOrigin = Array[newx,newy]
      newLeftChild.addRight({:xy => newOrigin, :length => newLength, :width => newWidth})
    end
    
    # left node of the right child is the left vertical space below the part placed 
    #right node is the vertical spaces remaining
    # if width remaining is 0, then we don't need a left node
    #newWidth = leaf.rect[:width] - layoutPart.getWidthPx
    newWidth = leaf.rect[:width] - layoutPart.getWidth
    if newWidth != 0
      # x remains the same since the part is placed in top left corner
      # y is old y + layout part width
      newx = leaf.rect[:xy][0]
      #newy = leaf.rect[:xy][1]+layoutPart.getWidthPx
      newy = leaf.rect[:xy][1]+layoutPart.getWidth
      #newLength = layoutPart.getLengthPx
      newLength = layoutPart.getLength
      # create and add a new left node to the node just created
      newOrigin = Array[newx,newy]
      newRightChild.addLeft({:xy => newOrigin, :length => newLength, :width => newWidth})
    end
    
    # right node of the right child is the right vertical space to the right of the part placed 
    #newLength = leaf.rect[:length] - layoutPart.getLengthPx
    newLength = leaf.rect[:length] - layoutPart.getLength
    if newLength != 0
      # y remains the same since the part is placed in top left corner
      # x is old x + layout part length
      newy = leaf.rect[:xy][1]
      #newx = leaf.rect[:xy][0]+layoutPart.getLengthPx
      newx = leaf.rect[:xy][0]+layoutPart.getLength
      newWidth = leaf.rect[:width]
      # create and add a new left node to the node just created
      newOrigin = Array[newx,newy]
      newRightChild.addRight({:xy => newOrigin, :length => newLength, :width => newWidth})
    end
  end
  
  # use a recursive search to find the best spot for a part
  # best fit means least wastage ie: the area of the piece to place comes closes to the area of the space
  #from the given Node, return a result if it is a leaf node, othewise go left, then go right recursively.
  # returns the chosen best leaf node
  def findBestFit(node,length,width)
    # nothing here if this is a nil node
    return nil if node == nil
    # am i in a node or a leaf
    leaf = false    
    leaf = true if node.getNodeType == "leaf"
    #look at the leaf if we are a leaf
    if leaf
      puts "look at a leaf" if $verbose
      puts "ll=" + node.rect[:length].to_l.to_s + "lw="  + node.rect[:width].to_l.to_s if $verbose
      puts "pl=" + length.to_l.to_s + "pw=" + width.to_l.to_s if $verbose
      # won't fit if length is too short
      return nil if length > node.rect[:length]
      # won't fit if width is too narrow
      return nil if width > node.rect[:width]
      # fits, so return as a potential best fit
      return node
    end
    # it's a node
    puts "it's a node" if $verbose
    #go left
    bestLeft = findBestFit(node.left,length,width) 
    #go right
    bestRight = findBestFit(node.right,length,width) 
    # now determine which is the best. No brainer if one or both are nil
    return nil if bestLeft == nil && bestRight == nil
    return bestLeft if bestRight== nil
    return bestRight if bestLeft == nil
    #otherwise both are potentials and we have to choose one
    # pick based on best fit  ie: least amount of waste left or the one further to the origin of the board or both. User can select
    # the bias, otherwise we use both rules and try to pack the parts from left to right
    # ( note area on the board must >= the part size because of earlier decisions )
    area = length*width
    ruleA = ( ((bestLeft.rect[:length]*bestLeft.rect[:width]) - area) <= ((bestRight.rect[:length]*bestRight.rect[:width]) - area)  ) \
            && @layoutOptions[:layoutRuleA]
    ruleB = ( bestLeft.rect[:xy][0] < bestRight.rect[:xy][0] ) && @layoutOptions[:layoutRuleB]
    return bestLeft if ruleA || ruleB
    return bestRight
  end
  
  def getAreaOfParts(node)
    return 0 if node == nil
    return 0 if node.getNodeType == "leaf"
    # add up all parts to the left of the node
    areaLeft = getAreaOfParts(node.left)
    # add up all parts to the right of the node
    areaRight = getAreaOfParts(node.right)
    #puts (areaLeft + areaRight + node.getPartArea).to_s if $verbose1
    return (areaLeft + areaRight + node.getPartArea)
  end
  
  # alternate method of getting the area covered by the parts on a board
  def areaOfPartsOnBoardFromList
    partInBoardListArray = @partInBoardList.getList
    totalArea = 0
    partInBoardListArray.each { |part|
        totalArea += part.getLengthPx*part.getWidthPx
    }
    return totalArea
  end
  
  # Note: This does not seem to return accurate results, though not sure why at this point. Who can find the bug?
  def areaOfPartsOnBoard
    # find all nodes with parts and add up the areas
    return getAreaOfParts(@root)
  end
  
  #return the layout parts on this board
  def getBoardPartList
    return @partInBoardList
  end
  
  def boardFull
    @boardFull
  end
  def setBoardFull
    @boardFull = true
    # when board is declared full, then let's calculate the efficiency
    # add up the area of all of the parts on this board - assume any extra thickness is waste
    # divide by the area of the board
    # we can work these numbers in pixels - good as any - as long as the units are consistent
    #usedArea = areaOfPartsOnBoard
    usedArea = areaOfPartsOnBoardFromList
    @usedAreaPercentage = ((usedArea/@board.getAreaPx)*100).round_to(2)
  end
  def getUsedAreaPercentage
    @usedAreaPercentage
  end
  def board
    @board
  end
  
  def to_s
    return @board.to_s + (' (' + getUsedAreaPercentage.to_s + '%)' if getUsedAreaPercentage != 0 )
  end
  
end
