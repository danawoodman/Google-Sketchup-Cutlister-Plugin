#-----------------------------------------------------------------------------
#########################
# Renderer superclass   #
#########################
class Renderer
  def initialize(modelName)
    @modelName = modelName
  end
  def getTitle(title)
  end ## end getTitle

  def getHeaderRow(headers)
  end ## end getHeaderRow

  def getFooterRow()
  end ## end getFooterRow

  def getRow(columns)
  end ## end getRow

  def getAmount(amount)
  end ## end getAmount

  def getBlankLine()
  end ## end getBlankLine

end ## end class Renderer

#########################
# HtmlRenderer          #
#########################
class HtmlRenderer < Renderer
  
  def pageHeading(modelTitle)
    html = ""
    # experimental - label the window with the name of the model
    #html += "<\body><head><title>+modelTitle+<\title><\head><body>"
    # display the model name at the top of the page
    # make sure to htmlize the mode name
    puts modelTitle
    modelTitle = modelTitle.to_html
    puts modelTitle
    html +="<BR><B><H4 style=\"color:#7d7d4f\">"+modelTitle+"</H4></B>"
    return html
  end

  def getTitle(tableTitle)
    colspan = 2
    html = ""
    html = html+"<BR><B><H4 style=\"color:#7d7d4f\">"+tableTitle+"</H4></B>"
   # html = html+"<table cellpadding=2 cellspacing=0 border=1 frame=border >\\n"
   # html = html+"<table cellpadding=2 cellspacing=0 frame=hsides bgcolor=#ECF0F3>\\n"
    html = html+"<table id=\"cutlistTable\" cellpadding=4 cellspacing=0 frame=border border=\"1\" bordercolor=#8c8c8c rules=groups bgcolor=#ECF0F3>"
    return html
  end ## end getTitle

  def getHeaderRow(headers)
    html = ""
    html = html+"<tr>"
    for h in headers
      html = html+"<td>"
      html = html+"<B>"+h+"</B>"
      html = html+"</td>"
    end ## end for
    html = html+"</tr>"
    return html
  end ## end getHeaderRow

  def getFooterRow()
    html = ""
    html = html+"</table>"
    return html
  end ## end getFooterRow

  def getRow(columns)
    html = ""
    html = html+"<tr>"
    for c in columns
      html = html+"<td>"
      html = html+c.to_html
      html = html+"</td>"
    end ## end for
    html = html+"</tr>"
    return html
  end ## end getRow

  def getAmount(amount)
    html = ""
    html = html+"<tr>"
    html = html+"<td>"
    html = html+amount
    html = html+"</td>"
    html = html+"</tr>"
    return html
  end ## end getArea

  def getBlankLine()
   return "<BR>"
  end ## end getBlankLine

end ## end classHtmlRenderer

#-----------------------------------------------------------------------------
# Layout renderer base class
#-----------------------------------------------------------------------------
class LayoutRenderer
  def initialize(modelName)
    @modelName = modelName
    @divNumber = 0
    @divName = ""
    @offsetY = 0
    @page1 = true
    @newSection = true
    @pageHeight = 0
  end
  def drawPart(penThickness,color,label,x,y,length, height)
  end
  def drawBoard(penThickness,color,label,x,y,length,height)
  end
end


#-----------------------------------------------------------------------------
# html renderer to write a java script to draw
# using wz_jsgraphics.js
#-----------------------------------------------------------------------------
class HtmlLayoutRenderer  < LayoutRenderer
  # offsetting is used for absolute positioning within a div
  # each section and a single board is on 1 div
  # each new board or sheet is on its own div
  # Each div is added into the body before the buttons, so it appears last
  # each div parent has relative positioning within the document and then the html for the drawing is placed
  # in its own child div, which uses absolute positioning.
  # This way, the document flows naturally but is actually in several consecutive divs, thus avoiding any
  # browser overflows of any current window.
  # Printing is another matter, since the html for displaying and the html for printing is different because
  # the trick being relied on for displaying boxes using divs does not display when printing.
  # Therefore the wz_jsgraphics script smultaneously produced a second version of the html
  # For printing, a similar document structure is rebuilt, containing the second version of the html
  def offsetY(y)
    return y if @page1
    return (y-@offsetY)
  end
  
  def header(x,y)
    # we'll need to add some things to the heading later so remember where it was
    html = ""
    #html = html + htmlHeader
    #html = html + scriptHeader
    html = html + functionHeader
    return html
  end

  def displayTextNoOffset(x,y,string)
    html = ""
    html += setColor("#7d7d4f")
    html += " cutlistLayout.setFont(\"verdana\",\"12px\",Font.BOLD);"  
    html += " cutlistLayout.drawString(\"#{string}\",#{x},#{y});"
    return html
  end
  
  def displayText(x,y,string)
    y = offsetY(y)
    html = ""
    html += displayTextNoOffset(x,y,string)
    return html
  end

  def displayBoardFeet(string)
    html = ""
    x = @headingX + 500
    y = @headingY + 10
    html += displayTextNoOffset(x,y,string)
    return html
  end
  
  def displayEfficiency(string)
    html = ""
    x = @headingX + 330
    y = @headingY + 10
    html += displayTextNoOffset(x,y,string)
    return html
  end
  
  # input numbers startx,starty,length,height must be integer not float
  # color must be a color name string( eg 'blue' ) or hex string( eg #0000ff)
  # x,y is top left corner
  # This draws a filled rectangle using the color selected, with a black border and the text in the center
  def drawPart(penThickness,color,label,x,y,length, height)
    y = offsetY(y)
    #label is placed in the approx center of the box
    labely = y + (height/2) -5
    html = ""
    html = html + setColor(color)
    html = html + " cutlistLayout.fillRect(#{x},#{y},#{length},#{height});"
    html = html + " cutlistLayout.setStroke(#{penThickness});"
    html = html + setColor("black")
    html = html + " cutlistLayout.setFont(\"arial\",\"10px\",Font.BOLD);"  
    # outline the rectangle using black
    html = html + " cutlistLayout.drawRect(#{x},#{y},#{length},#{height});"
    html = html + " cutlistLayout.drawStringRect(\"#{label}\",#{x},#{labely},#{length},\"center\");"
    return html
  end
  
  # a board starts off as a box, the background shade or pattern indicating it is unused
  # it has a label just above the board which is freeform text and can be used to indicate size or any notes
  # specific to the board
  # The color is the color of the background. All text is in black
  def drawBoard(penThickness,color,label,x,y,length,height)
    html = ""
    labely = y-20
    # a board starts a new offset if it the 2nd board in a section\
    # if it is a new section, then the first board is not offset.
    puts "x1=" + x.to_s + " y1=" + y.to_s + " labely1=" + labely.to_s + " offsetY1=" + @offsetY.to_s if $verbose
    # once we have at least one board, the newSection flag is turned off
    # If this board is not part of the new section ( in which the title and the board are placed in the same container)
    # then start a new page now before adding the board
    if @newSection == false
      @page1 = false  #definitely not page 1 anymore if we are creating a new page
      html += newPage( height)
      @offsetY = labely # since we are starting a new page, reset the value of the Y offset
    else
      #adjust the size of the current page to the height of the board if necessary
      html += adjustPageHeight(height)
    end
    y = offsetY(y)
    labely = offsetY(labely)
    puts "x2=" + x.to_s + " y2=" + y.to_s + " labely1=" + labely.to_s + " offsetY2=" + @offsetY.to_s if $verbose
    # put each board in its own cell so it becomes scrollable
    #html += "cutlistLayout.htm += \'<div style=\"position:relative;width:#{length+50}px;height:#{height+50}px;\"><table cellpadding=\"0\" cellspacing=\"0\"><tr><td>\';"
    html += setColor(color)
    html += " cutlistLayout.fillRect(#{x},#{y},#{length},#{height});"
    html += setColor("black")
    html += " cutlistLayout.setFont(\"arial\",\"10px\",Font.BOLD_ITALIC);"
    # Note: do not call hatch anymore for window layout display. Using wsgrpahics to
    # produce crosshatching proves to be a huge performance hit for only some aesthetic gain
    #html += hatch(x,y,length,height)
    html += " cutlistLayout.setStroke(#{penThickness});"
    html += " cutlistLayout.drawRect(#{x},#{y},#{length},#{height});"
    html += " cutlistLayout.drawStringRect(\"#{label}\",#{x},#{labely},#{length},\"left\");"
    #html += "cutlistLayout.htm += \'<\/td><\/tr><\/table><\/div>\';"
    #html += "cutlistLayout.paint();"
    #end of a new section
    @newSection = false
    return html
  end
  
  # hatch fills in hatching within a board
  # it is always called from within drawBoard, so we do not adjust x and y offsets becasue there are
  # already offset.
  def hatch(x,y,length,height)
    html = ""
    html = html + " cutlistLayout.setStroke(Stroke.DOTTED);"
    lineSpacing = 20
    totalLines = ((length+height)/lineSpacing).floor
    # dim1 should always be the shorter of the two sides
    if height <= length
      dim1 = height
      dim2 = length
      horizontal=true
    else
      dim1 = length
      dim2 = height
      horizontal=false
    end
    #puts totalLines.to_s
    # y= -x+i*lineSpacing is the equation of the diagonals since positive y axis is towards the bottom of the screen
    1.upto(totalLines){ |i|
      if (i*lineSpacing <= dim1)
        startx=x
        endy=y
        starty=y+(x+i*lineSpacing) - startx
        endx=x+(y+i*lineSpacing) - endy
      elsif ( (i*lineSpacing > dim1) && (i*lineSpacing <= dim2) )
        if horizontal
          starty=y+height
          endy=y
          startx= x+ (y+i*lineSpacing) - starty
          endx=x+ (y+i*lineSpacing) - endy
        elsif
          startx=x
          endx=x+length
          endy=y+(x+i*lineSpacing)-endx
          starty=y+(x+i*lineSpacing)-startx
        end
      else
        starty=y+height
        endx=x+length
        startx=x+ (y+i*lineSpacing) - starty
        endy=y+ (x+i*lineSpacing) - endx
      end
      
      #draw the line from (startx,starty) to (endx,endy)
      html = html + "cutlistLayout.drawLine(#{startx},#{starty},#{endx},#{endy});"
    }
    return html
  end
  
  def pageHeading(x,y,string)
    y = offsetY(y)
    html = ""
    # display the model name at the top of the page
    html = html + setColor("#7d7d4f")
    html = html + " cutlistLayout.setFont(\"verdana\",\"14px\",Font.BOLD);"
    string = string.to_html
    html = html + " cutlistLayout.drawString(\"#{string}\",#{x},#{y});"
    return html
  end
  
  #Section heading starts a new div and set new section to true
  #and recalculate our offsets
  def sectionHeading(x,y,type)
    if @newSection == false
      # this must be the start of a subsequent section since we initialize with newSection = true
      # because this is a new section page1 must also be turned off
      @page1 = false
      @newSection = true
    end
    #reset the offsets at the beginning of a new section
    @offsetY = y
    #adjust y by the offsets
    y = offsetY(y)
    html = ""
    @headingX = x
    @headingY = y
    # start the new section on a new page unless this is the first page ( already a container )
    # start with a small container and then adjust up later as necessary
    if !@page1
      html += newPage(100)
    end
    html = html + setColor("#7d7d4f")
    html = html + " cutlistLayout.setFont(\"verdana\",\"20px\",Font.BOLD);"  
    html = html + " cutlistLayout.drawString(\"Cutting Diagram  - #{type}\",#{x},#{y});"
    return html
  end
  
  def setColor(color)
    return " cutlistLayout.setColor(\"#{color}\");"
  end
  
  def pageEnding(x,y,string)
    html = ""
    return html
  end
  
  def footer
    html = ""
    html += functionFooter
    return html
  end
    
  def functionHeader
    html = ""
    html += "function drawLayout()"
    html += "{"
    #html = html + "  cutlistLayout.setPrintable(true);"
    return html
  end
  
  def adjustPageHeight(height)
    # increase the height of the current page if needed
    html= ""
    if (@pageHeight < (height+200))
      @pageHeight = height + 200
      html += "cutlistLayout.cont.style.height = \"#{@pageHeight}px\";"
    end
    return html
  end
  
  def newPage(height)
    # every time we paint, start a new container within the html, so that we don't
    # overflow the container. Each new element represents another relatively
    # positioned block, in which there will be absolute positioning for the boards
    # In the display, this won't make any difference, but when printing we have
    # more control.
    # (experimental)
    # use the height to determine the size of the canvas, increase to accommodate labels and titles
    @pageHeight = height + 100
    @divNumber += 1
    contName = "layoutDiv" + @divNumber.to_s
    html = ""
    html += "var body = cutlistLayout.wnd.document.getElementsByTagName(\"body\")[0];"
    html += "var buttonDivObject = cutlistLayout.wnd.document.getElementById(\"buttons\");"
    html += "cutlistLayout.cont = cutlistLayout.wnd.document.createElement(\"div\");"
    html += "body.insertBefore(cutlistLayout.cont,buttonDivObject);"
    html += "cutlistLayout.cont.id = \"#{contName}\";"
    html += "cutlistLayout.cont.className = \"layout\";"
    html += "cutlistLayout.cont.style.visibility = \"visible\";"
    html += "cutlistLayout.cont.style.height = \"#{@pageHeight}px\";"
    html += "cutlistLayout.cont.style.position=\"relative\";"
    divName = "div" + @divNumber.to_s
    html += "cutlistLayout.cnv = cutlistLayout.wnd.document.createElement(\"div\");"
    html += "cutlistLayout.cnv.id = \"#{divName}\";"
    html += "cutlistLayout.cnv.className = \"graphicScreen\";"
    html += "cutlistLayout.cnv.style.fontSize=0;"
    html += "cutlistLayout.cont.appendChild(cutlistLayout.cnv);"
    puts "Creating div=" + contName + " with subdiv=" + divName if $verbose1
    
    # Make another div within the layoutDiv for the printing html
    divPrintName = "divPrint" + @divNumber.to_s
    html += "cutlistLayout.cnvPrint = cutlistLayout.wnd.document.createElement(\"div\");"
    html += "cutlistLayout.cnvPrint.id = \"#{divPrintName}\";"
    html += "cutlistLayout.cnvPrint.className = \"graphicPrint\";"
    html += "cutlistLayout.cnvPrint.style.fontSize=0;"
    html += "cutlistLayout.cont.appendChild(cutlistLayout.cnvPrint);"
    puts "Creating Print div=" + contName + " with subdiv=" + divPrintName if $verbose1
    return html
  end
  
  def draw
    html = ""
    #html += "  results += cutlistLayout.htmRpc();"
    #html += "  results += cutlistLayout.htm;"
    html += "  cutlistLayout.paint();"
    return html
  end
  
  def functionFooter
    html = ""
    html += "  cutlistLayout.paint();"
    html += "}"
    html += "var cutlistLayout = new jsGraphics(\"layoutDiv\");"
    return html
  end
  
end

#-----------------------------------------------------------------------------
# svg renderer to generate svg format text output description of the graphics
# which can then be displayed using an svg browser
#-----------------------------------------------------------------------------
class SvgLayoutRenderer  < HtmlLayoutRenderer
  def functionHeader
    html = ""
    html += "<?xml version=\"1.0\" standalone=\"no\"?>\n"
    html += "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \n"
    html += "  \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n"
    html += " \n"
    html += "<svg width=\"100%\" height=\"100%\" version=\"1.1\" \n"
    html += "  xmlns=\"http://www.w3.org/2000/svg\">\n"
    return html
  end
  
  def text(x,y,string,color,font,fontSize,fontWeight,fontStyle,textAnchor)
    html = ""
    html += "<text"
    html += " x=\"#{x}\" y=\"#{y}\" fill=\"#{color}\""
    html += " font-family=\"#{font}\" font-size=\"#{fontSize}\" font-weight=\"#{fontWeight}\" font-style=\"#{fontStyle}\""
    html += " text-anchor=\"#{textAnchor}\">"
    html += "#{string}</text>\n"
    return html
  end
  
  def displayText(x,y,string)
    html = ""
    html += text(x,y,string,"#7d7d4f","Verdana",12,"bold","normal","start")
    return html
  end
  
  def pageHeading(x,y,string)
    html = ""
    # Always display the model name at the top
    html += text(x,y,string,"#7d7d4f","Verdana",14,"bold","normal","start")
    return html
  end
  
  def sectionHeading(x,y,type)
    # record where our cutting diagram heading ends up so we can come back and add efficiency summaries to it later
    html = ""
    @headingX = x
    @headingY = y
    y += 10
    # Display the cutting diagram header and board type
    string = "Cutting Diagram  - #{type}"
    html += text(x,y,string,"#7d7d4f","Verdana",20,"bold","normal","start")
    return html
  end
  
  def drawPart(penThickness,color,label,x,y,length, height)
    #label is placed in the approx center of the box
    labely = y + (height/2) +2
    labelx = x + (length/2) + 2
    html = ""
    html = ""
    html += "<rect"
    html += " x=\"#{x}\" y=\"#{y}\" fill=\"#{color}\" width=\"#{length}\" height=\"#{height}\" stroke=\"black\" stroke-width=\"#{penThickness}\">"
    html += "</rect>\n"
    html += text(labelx,labely,label,"black","arial",8,"bold","normal","middle")
    return html
  end
    
  def drawBoard(penThickness,color,label,x,y,length,height)
    labely = y-10
    html = ""
    html += "<rect"
    html += " x=\"#{x}\" y=\"#{y}\" fill=\"#{color}\" width=\"#{length}\" height=\"#{height}\" stroke=\"black\" stroke-width=\"#{penThickness}\">"
    html += "</rect>\n"
    html += text(x,labely,label,"black","arial",10,"bold","italic","start")
    html += hatch(x,y,length,height)
    return html
  end
  
  def draw
    html = ""
    return html
  end
  
  def hatch(x,y,length,height)
    html = ""
    lineSpacing = 20
    totalLines = ((length+height)/lineSpacing).floor
    # dim1 should always be the shorter of the two sides
    if height <= length
      dim1 = height
      dim2 = length
      horizontal=true
    else
      dim1 = length
      dim2 = height
      horizontal=false
    end
    #puts totalLines.to_s
    # y= -x+i*lineSpacing is the equation of the diagonals since positive y axis is towards the bottom of the screen
    1.upto(totalLines){ |i|
      if (i*lineSpacing <= dim1)
        startx=x
        endy=y
        starty=y+(x+i*lineSpacing) - startx
        endx=x+(y+i*lineSpacing) - endy
      elsif ( (i*lineSpacing > dim1) && (i*lineSpacing <= dim2) )
        if horizontal
          starty=y+height
          endy=y
          startx= x+ (y+i*lineSpacing) - starty
          endx=x+ (y+i*lineSpacing) - endy
        elsif
          startx=x
          endx=x+length
          endy=y+(x+i*lineSpacing)-endx
          starty=y+(x+i*lineSpacing)-startx
        end
      else
        starty=y+height
        endx=x+length
        startx=x+ (y+i*lineSpacing) - starty
        endy=y+ (x+i*lineSpacing) - endx
      end
      
      #draw the line from (startx,starty) to (endx,endy)
    html += "<line"
    html += " x1=\"#{startx}\" y1=\"#{starty}\" x2=\"#{endx}\" y2=\"#{endy}\" "
    html += "stroke=\"grey\" stroke-width=\"1\" />\n"
    }
    return html
  end
  
  def pageEnding(x,y,string)
    html = ""
    #html += "  </page>\n"
    return html
  end
      
  def functionFooter
    html = ""
    html = html +"</svg>\n"
    return html
  end
end


#########################
# FileRenderer          #
#########################
class FileRenderer < Renderer
  
  def initialize(modelName)
    # call any intialisation required for the base class
    super(modelName)
    locale = Sketchup.get_locale
    puts "locale=" + locale
    if ( locale == 'en-US' ||
         locale == 'en-GB' )
      # The following line, if uncommented, uses tab characters instead of ',' as the delimiter
      #@delimiter = "\ci"
      @delimiter = ","
    else
      @delimiter = ";"
    end
  end

  def getTitle(title)
    # don't print a blank line if there is no title - this is important for CutList Plus which looks for headings
    # in the first line
    txt = ""
    txt = title+"\n" if title != ""
    return txt
  end ## end getTitle

  def getHeaderRow(headers)
    txt = ""
    for h in headers
      txt = txt+h
      txt = txt+@delimiter 
    end ## end for
    txt = txt+"\n"
    return txt
  end ## end getHeaderRow

  def getFooterRow()
    return ""
  end ## end getFooterRow

  def getRow(columns)
    txt = ""
    for c in columns
      txt = txt+c
      # do any text processing on csv fields - eg: remove the ~
      txt = txt.to_csv
      txt = txt+@delimiter 
    end ## end for
    txt = txt+"\n"
    return txt
  end ## end getRow

  def getAmount(amount)
    return amount+"\n"
  end ## end getArea

  def getBlankLine()
   return "\n"
  end ## end getBlankLine

end ## end class FileRenderer
#-----------------------------------------------------------------------------

