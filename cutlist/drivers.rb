#-----------------------------------------------------------------------------
# base class for all output generator types, html, or file
# This class is used to drive the different output parts ie: determine what needs to be 
# output and use the appropriate renderers to produce the output
#-----------------------------------------------------------------------------
class OutputDriver
  def initialize(compact,showComps, showSheet, showParts, volumeInMetric,solidParts,sheetParts,hardwareParts,mname)
    @compact = compact
    @showComps = showComps
    @showSheet = showSheet
    @showParts = showParts
    @showVolumeInMetric = volumeInMetric
    @solidParts = solidParts
    @sheetParts = sheetParts
    @hardwareParts= hardwareParts
    @modelName = mname
  end
  
  # open any files required, select a renderer
  def openFiles
    @renderer = nil
  end
  
  def openRenderer
  end
  
  # perform necessary rendering to produce requested output format
  def openParts
    return if (@renderer == nil)
    
    if(@showComps)
      if (@compact)
        @component = CompactComponent.new(@renderer,@showVolumeInMetric)
#	compact list is sorted by component names
        @solidParts.sortByName
      else
        @component = Component.new(@renderer,@showVolumeInMetric)
      end
    end # showComps
    
    if (@showSheet)
      if (@compact)
        @sheet = CompactSheet.new(@renderer,@showVolumeInMetric)
#	compact list is sorted by component names
        @sheetParts.sortByName
      else
        @sheet = Sheet.new(@renderer,@showVolumeInMetric)
      end
    end # showSheet
    
    if @showParts
      @part = CompactPart.new(@renderer,@showVolumeInMetric)
    end
    
  end # openParts
  
  # steps required to produce the requested output
  def run
    openFiles
    openRenderer
    openParts
    render
    close
  end
  
  # close any files which are open
  def closeFiles
  end
  
  # display results of the rendering, either 'output done' msg or display the file
  def displayResults
  end
  
  # steps after rendering is complete
  def close
    closeFiles
    displayResults
  end
end

#-----------------------------------------------------------------------------
# output driver for all file based output
#-----------------------------------------------------------------------------
class FileOutputDriver < OutputDriver
  def initialize(compact,showComps, showSheet, showParts, volumeInMetric,solidParts,sheetParts,hardwareParts,mname,mpath,filename)
    super(compact,showComps, showSheet, showParts, volumeInMetric,solidParts,sheetParts,hardwareParts,mname)
    @mpath = mpath
    @filename = filename
    @modelName = mname
  end
  
  def openFiles
    @namecsv = @mpath + "/" + @modelName + "_" + @filename
    @file = File.new(@namecsv,"w")
  end
  
  def openRenderer
    @renderer = FileRenderer.new(@modelName)
  end
    
  def render
    if(@showComps && !@solidParts.empty?)
      @file.puts(@component.to_s(@solidParts.getList))
    end
    if(@showSheet && !@sheetParts.empty?)
      @file.puts(@sheet.to_s(@sheetParts.getList))
    end
    if(@showParts && !@hardwareParts.empty?)
      @file.puts(@part.to_s(@hardwareParts))
    end
  end
  
  def closeFiles
    @file.close
  end
  
  def displayResults
    UI.messagebox("Cut List written into: \n\n" + @namecsv + "  \n")
  end

end

#-----------------------------------------------------------------------------
# output driver for cutlist plus output
#-----------------------------------------------------------------------------
class ClpFileOutputDriver < FileOutputDriver
  # perform necessary rendering to produce requested output format
  def openParts
    return if (@renderer == nil)
    
    if(@showComps)
      if (@compact)
        @component = CompactClpComponent.new(@renderer,@showVolumeInMetric)
      else
        @component = ClpComponent.new(@renderer,@showVolumeInMetric)
      end
    end # showComps
    
    if (@showSheet)
      if (@compact)
        @sheet = CompactClpSheet.new(@renderer,@showVolumeInMetric)
      else
        @sheet = ClpSheet.new(@renderer,@showVolumeInMetric)
      end
    end # showSheet
    
    #if @showParts
    #  @part = CompactPart.new(@renderer,@showVolumeInMetric)
    #end
  end
  
  def displayResults
    UI.messagebox("Cut List Plus import file written into: \n\n" + @namecsv + "  \n")
  end
end

#-----------------------------------------------------------------------------
# output driver for all html based output
#-----------------------------------------------------------------------------
class HtmlOutputDriver <OutputDriver
  def openFiles
    @html = ""
  end
  
  def openRenderer
    @renderer = HtmlRenderer.new(@modelName)
  end
  
  def startPage
#    @html += @renderer.header(@x,@y)
    pageHeading = "Project: " +@modelName.to_s
    @html += @renderer.pageHeading(pageHeading)
#    pageYIncrement(30)
  end
  
  def render
    startPage
    if(@showComps && !@solidParts.empty?)
      @html += @component.to_s(@solidParts.getList)
    end
    if(@showSheet && !@sheetParts.empty?)
      @html += @sheet.to_s(@sheetParts.getList)
    end
    if(@showParts && !@hardwareParts.empty?)
      @html += @part.to_s(@hardwareParts)
    end
  end
  
  # an opportunity to do something whenever y coordinate reaches a certain value
  # default is to only increment the y coordinate
  def pageYIncrement(yIncrement)
    @y += yIncrement
  end
  
  # no files to close
  def closeFiles
  end
  
  def displayResults
    @resultGui = ResultGui.new(@modelName)
    @resultGui.show(@html)
  end
end

#-----------------------------------------------------------------------------
# output driver for the layout output
#-----------------------------------------------------------------------------
class HtmlLayoutDriver < HtmlOutputDriver
  def initialize(layoutBoards,layoutSheets,unPlacedParts, mname)
    @layoutBoards = layoutBoards
    @layoutSheets = layoutSheets
    @unPlacedParts = unPlacedParts
    @modelName = mname
    @pageNumber = 1
    @totalEfficiency = 0
  end
  
  def openRenderer
    @renderer = HtmlLayoutRenderer.new(@modelName)
  end
  
  # overwrite the base method as we don't need to open the same parts
  # later we may open the layout Parts list here or something
  def openParts
  end

  def renderLayoutBoards(layoutBoards,type)
      
    if ( layoutBoards != nil && layoutBoards.length > 0 )
      @html += @renderer.sectionHeading(@x,@y,type)
      
      # display board efficiency
      calculateUtilisation(layoutBoards)
      @html += @renderer.displayEfficiency(getTotalEfficiencyString.to_html)
      
      # display board feet required for layout ( # of boards * bdft for each board)
      calculateTotalLayoutBoardFeet(layoutBoards)
      @html += @renderer.displayBoardFeet(getTotalBoardFeetString(layoutBoards).to_html)
      
      # increment y position before starting on the boards
      pageYIncrement(50)
      
      # draw all boards/sheets and layout parts on the boards/sheets
      layoutBoards.each {|layoutBoard| renderBoard(layoutBoard) }
    end
  end
    
  def startPage
    @x = 30
    @y = 30
    @html += @renderer.header(@x,@y)
    pageHeading = "Project: " +@modelName.to_s
    @html += @renderer.pageHeading(@x,@y, pageHeading)
    pageYIncrement(30)
  end
  
  def endPage
    pageEnding = "Page: " + @pageNumber.to_s
    @html += @renderer.pageEnding(@x,@y, pageEnding)
    @html += @renderer.footer
  end
  
  def render
    startPage
    
    # if both were nil, then at least say something!
    if ( (@layoutBoards == nil || @layoutBoards.length == 0) && 
         (@layoutSheets == nil || @layoutSheets.length == 0) )
      @html += @renderer.displayText(@x,@y,"No parts to layout")
      pageYIncrement(30)
    else
      renderLayoutBoards(@layoutBoards,"Boards")
      renderLayoutBoards(@layoutSheets,"Sheets") 
    end
    #debug
    puts "unplacedParts is nil" if (@unPlacedParts == nil ) && $verbose1
    puts "unplacedParts is empty" if  (@unPlacedParts != nil ) && (@unPlacedParts.empty? ) && $verbose1
    #debug
    #display any uplaced parts
    if @unPlacedParts != nil  && !@unPlacedParts.empty?
      puts "unplaced parts list has " + @unPlacedParts.getList.length.to_s + " entries" if $verbose1
      showUnPlacedParts(@unPlacedParts)
    end
    endPage
  end
  
  def showUnPlacedParts(unPlacedParts)
    # update pageEmpty as we have some unplaced parts to display
    @pageEmpty = false
    unPlacedPartsList = unPlacedParts.getList
    @html += @renderer.displayText(@x,@y,"Parts not placed ( Part(L,W,T) Material):")
    pageYIncrement(30)
    unPlacedPartsList.each { |part|
      @html += @renderer.displayText(@x,@y,part.summary.to_html)
      pageYIncrement(20)
    }
  end

  def calculateTotalLayoutBoardFeet(layoutBoards)
    if layoutBoards != nil
      @layoutBoardFeet = 0
      layoutBoards.each { |layoutBoard|
        @layoutBoardFeet += layoutBoard.board.getBoardFeet
      }
    end
  end

  def getTotalBoardFeetString( layoutBoards )
    if ( layoutBoards != nil && layoutBoards.length > 0 )
      return "Total used for layout: " + @layoutBoardFeet.to_s + " " + ( layoutBoards[0].board.getBoardFeetUnitsString )
    else
      return ""
    end
  end
  
  def calculateUtilisation(layoutBoards)
    # go through each board and get the efficiency of each, average over the number of boards
    if layoutBoards != nil
      x = 0
      efficiency = 0
      @totalEfficiency = 0
      layoutBoards.each { |layoutBoard|
        x += 1
        efficiency += layoutBoard.getUsedAreaPercentage
        @totalEfficiency = (efficiency/x).round_to(2)
      }
    end
  end
  
  def getTotalEfficiencyString
    return "Efficiency = " + @totalEfficiency.to_s + "%"
  end
  
  def renderBoard(layoutBoard)
    # update pageEmpty as soon as we know we have a board to display
    @pageEmpty = false
    #first extract the board dimensions and details and render the board
    board = layoutBoard.board
    @html += @renderer.drawBoard(2,"#cacaaf",layoutBoard.to_s.to_html,@x,@y,board.getLengthPx,board.getWidthPx)
    # now print off each part on this board
    partsList = layoutBoard.getBoardPartList
    partsListArray  = partsList.getList
    partsListArray.each{ |part| renderPart(part) }
    # draw each board 1 at a time - faster output it seems, because it has less to draw each time?
    @html += @renderer.draw
    # move next y coordinate down by board width + 50
    pageYIncrement(board.getWidthPx+50)
  end
  
  def renderPart(part)
    # get the relative coordinates for this part ( returns an array containing x,y)
    coords = part.getLocationOnBoardInPx
    @html += @renderer.drawPart(2,"#bcbc9a",part.getName.to_html,@x+coords[0],@y+coords[1],part.getLengthPx,part.getWidthPx)
  end
  
  # use the layout gui to display the output
  def displayResults
    @resultGui = LayoutGui.new(@modelName)
    #DEBUG
    #puts @html
    #DEBUG
    @resultGui.show(@html)
  end
end

#------------------------------------------------------------------------------
# SVG output driver for the layout output
#-----------------------------------------------------------------------------
class SvgLayoutDriver < HtmlLayoutDriver
  def initialize(layoutBoards,layoutSheets,unPlacedParts,mname,mpath)
    super(layoutBoards,layoutSheets,unPlacedParts,mname)
    @mpath = mpath
    @filename = "layout"
    @filenameSuffix = ".svg"
    @svgFileNameList  = Array.new()
  end
  
  def openRenderer
    @renderer = SvgLayoutRenderer.new(@modelName)
  end
  
  def openFiles
    @html = ""
    @nameSvg = @mpath + "/" + @modelName + "_" + @filename + "-p" + @pageNumber.to_s + @filenameSuffix
    @file = File.new(@nameSvg,"w")
    @pageEmpty = true
  end
  
  def pageYIncrement(yIncrement)
    if ( @y + yIncrement) >= 480
      endPage
      #close this file
      closeFiles
      #increment page number
      @pageNumber +=1
      #open a new file
      openFiles
      startPage
    else
      @y += yIncrement
    end
  end
    
  def displayResults
    svgFileListDisplay = ""
    @svgFileNameList.each { |file| svgFileListDisplay += file }
    fileString = " file:"
    fileString = " files:" if @svgFileNameList.length > 1
    UI.messagebox("SVG Layout written into " + @svgFileNameList.length.to_s + fileString + " \n\n" + svgFileListDisplay + "  \n")
  end
  
  def closeFiles
    @file.puts @html
    @file.close
    if (@pageEmpty == true )
      #delete the file as it is empty
      File.delete(@nameSvg)
    else
      # add this file name to the list of svg files
      @svgFileNameList.push(@nameSvg +"\n")
    end
  end
end

