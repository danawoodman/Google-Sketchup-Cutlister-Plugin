
# The Renderer class is a super-class that is sub-classed to create 
# different renderers such as CSV and HTML.
# 
# This class is just a shell to reference when sub-classing it and is not 
# actually used in the code other than to get it's sub-classes.
class Renderer
  
  def initialize
  end
  
  # Add a display name property for displaying in the web dialog UI.
  def self.display_name

    @display_name

  end
  
  # Add a description property for displaying in the web dialog UI.
  def self.description

    @description

  end
  
  def heading(label, opts)
    
    ''
    
  end
  
  def title(label)
    
    ''
    
  end
  
  def section_heading(label)
    
    ''
    
  end
  
  def rows(parts, labels, values)
    
    ''
    
  end
  
  def row(part)
    
    ''
    
  end
  
  def section_footer(parts)
    
    ''
    
  end
  
  def footer
    
    ''
    
  end
  
  def render(model, data)
    
    ''
    
  end

end


# Renders the cut list into an HTML page for instant viewing.
class HTMLRenderer < Renderer
  
  @display_name = "Web Page"
  @description = "Open a web page to view the cut list immediately. The web page can be printed for quick cut listing."
  
  def initialize(output_to_file = false)
    
    @output_to_file = output_to_file
    
  end
  
  # Add in the HTML page heading.
  def heading(title, opts)
    
    # Default CSS location.
    css_location = 'css/html-cutlist.css'
    
    # Check to see if the css_location option was passed to the heading method.
    opts.each { |key, value|
      
      # Check to see if the css_location key exists in the option hash.
      if key.to_s == "css_location"

        css_location = value

      end

    }

    # Find the support file.
    css_file_path = Sketchup.find_support_file(css_location.to_s, 'plugins/Cutlister/')
    
    css_file_contents = IO.read(css_file_path)
    
    puts "[HTMLRenderer.heading] css_location: #{css_location}" if $debug
    puts "[HTMLRenderer.heading] css_file_path: #{css_file_path}" if $debug
    
    return <<-EOS
    
      <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
      <html xmlns="http://www.w3.org/1999/xhtml"xml:lang="en" lang="en">
          <head>

              <meta http-equiv="content-type" content="text/html; charset=utf-8"/>

              <title>#{title}</title>

              <!-- Stylesheets -->
              <!--<link type="text/css" rel="stylesheet" href="#{css_file_path}" media="all" />-->
              <style type="text/css">
              
                #{css_file_contents}
              
              </style>

          </head>
          <body>

    EOS
    
  end
  
  # Create the title of the HTML page.
  def title(label)
    
    "<h1>#{label}</h1>"
    
  end
  
  # Add a heading to each section of parts.
  def section_heading(label)
    
    "<h3>#{label}</h3>"
    
  end
  
  # Represents the rows in the table.
  # 
  # The part data is passed in and then formatted.
  # 
  # Available fields are: cabinet_name, part_name, quantity, width, length, 
  # thickness, material. 
  # 
  # TODO: Add in notes, grain direction.
  def rows(parts, fields = [
                            [
                              "Sub Assembly",
                              "part.sub_assembly" 
                            ],
                            [ 
                              "Part Name", 
                              "part.part_name"
                            ],
                            [ 
                              "Quantity", 
                              "part.quantity"
                            ],
                            [ 
                              "Width",
                              "part.width.to_html_fraction"
                            ],
                            [ 
                              "Length",
                              "part.length.to_html_fraction"
                            ],
                            [ 
                              "Thickness", 
                              "part.thickness.to_html_fraction"
                            ],
                            [ 
                              "Material",
                              "part.material"
                            ]
                          ])
    
    # TODO: Get the order of items in a list to be configurable somehow...
    
    html = <<-EOS
    
      <table>
          <thead>
              <tr>
              
    EOS
    
    # List each heading for the coumns based on the `fields` parameter.
    fields.each { |f|
      
      html += "<th>#{f[0].to_s}</th>"
      
    }

                  
    html += <<-EOS
    
              </tr>
          </thead>
          <tbody>
    
    EOS
    
    if parts != nil
      
      all_rows = ''
      
      parts.each { |p| 
        
        all_rows += row(p, fields)
      
      }
      
      puts "[HTMLRenderer.rows] all_rows: #{all_rows}" if $debug
      
      html += all_rows.to_s
    
    else
      
      UI.messagebox "Sorry, there are no parts to cutlist...", MB_OK
    
    end
    
    html += <<-EOS
    
          </tbody>
      </table>
    
    EOS
    
    html
    
  end
  
  # Format each row in the table.
  def row(part, fields)
    
    # TODO: Add in notes, grain direction.
    html = "<tr>"

    fields.each { |f|
      
      val = eval f[1] # Eval can be dangerous if passing something wrong into it...

      puts "[HTMLRenderer.row] row values: #{f[0]}, #{val}\n\n" if $debug
      
      html += "<td>#{val.to_s}</td>"
      
    }
      
    html += "</tr>"
    
    puts "[HTMLRenderer.row] row html: #{html}" if $debug
    
    html
    
  end
  
  def section_footer(parts)
    
    # parts_collection = Parts.new(parts)
    # 
    # board_feet = parts_collection.get_board_feet
    # square_footage = parts_collection.get_square_footage
    # total_parts = parts_collection.get_total_parts
    # 
    # # TODO: Show count (hardware), board ft (solid), sq ft (sheet), or a 
    # # combination of all three depending on what parts are passed.
    # 
    # # Return the board feet, square footage and total parts.
    # <<-EOS
    # 
    #   <p><strong>Total Board Feet</strong> #{board_feet} board feet</p>
    #   <p><strong>Total Square Footage</strong> #{square_footage} sq. ft.</p>
    #   <p><strong>Total Parts</strong> #{total_parts}</p>
    # 
    # EOS
    ''
    
  end
  
  # Close out the HTML file
  def footer
    
    <<-EOS
       
              <p class="page-tools">
                  <input type="button" value="Print Page" class="button print" onClick="window.print();return false;" />
                  <input type="button" value="Close Page" class="button close grayed" onClick="window.close();" />
              </p>
      
          </body>
      </html>
    
    EOS
    
  end
  
  # Open a web page or save to a file.
  def render(model, data)
    
    # If the data is to be outputted to a file...
    if @output_to_file
      
      FileOutputFormat.new(model, data).run
      
    # If the data is to be outputted to a web page...
    else
      
      WebPageOutputFormat.new(model, data).run
      
    end
    
  end
  
end


# Exports the cut list into a Comma Seperated Values (CSV) file, which will
# work in programs like Mircosoft Excel (PC/Mac) and Apple iWork Numbers (Mac).
class CSVRenderer < Renderer
  
  @display_name = "CSV"
  @description = "Output the cut list in a .csv file that can be opened by programs like Microsoft Excel and iWork Pages."
  
  # Create the title of the HTML page.
  def title(label)
    
    "#{label}\n"
    
  end
  
  # Add a heading to each section of parts.
  def section_heading(label)
    
    "#{label}\n"
    
  end
  
  # Represents the roww in the table.
  # 
  # The part data is passed in and then formatted.
  # 
  # Available fields are: cabinet_name, part_name, quantity, width, length, 
  # thickness, material. 
  # 
  # TODO: Add in notes, grain direction.
  def rows(parts, fields = [
                            [
                              "Sub Assembly",
                              "part.sub_assembly" 
                            ],
                            [ 
                              "Part Name", 
                              "part.part_name"
                            ],
                            [ 
                              "Quantity", 
                              "part.quantity"
                            ],
                            [ 
                              "Width",
                              "part.width.to_fraction"
                            ],
                            [ 
                              "Length",
                              "part.length.to_fraction"
                            ],
                            [ 
                              "Thickness", 
                              "part.thickness.to_fraction"
                            ],
                            [ 
                              "Material",
                              "part.material"
                            ]
                          ])
    
    data = ''

    # List each heading for the coumns based on the `fields` parameter.
    fields.each { |f|
      
      data += "#{f[0].to_s},"
      
    }
    
    # Loop through each part and generate a row.
    if parts != nil
      
      all_rows = ""
      
      parts.each { |p| 
        
        all_rows += row(p, fields)
      
      }
      
      puts "[CSVRenderer.rows] all_rows: #{all_rows}" if $debug
      
      data += all_rows.to_s
    
    else
      
      UI.messagebox "Sorry, there are no parts to cutlist...", MB_OK
    
    end
    
    data
    
  end
  
  # Format each row in the table.
  def row(part, fields)
    
    data = ""
    
    # TODO: Add in notes, grain direction.
    fields.each { |f|
      
      val = eval f[1] # Eval can be dangerous if passing something wrong into it...

      puts "[CSVRenderer.row] row values: #{f[0]}, #{val}\n\n" if $debug
      
      data += "#{val.to_s},"
      
    }
    
    data
    
  end
  
  def section_footer(parts)
    
    # parts_collection = Parts.new(parts)
    # 
    # board_feet = parts_collection.get_board_feet
    # square_footage = parts_collection.get_square_footage
    # total_parts = parts_collection.get_total_parts
    # 
    # # TODO: Show count (hardware), board ft (solid), sq ft (sheet), or a 
    # # combination of all three depending on what parts are passed.
    # 
    # # Return the board feet, square footage and total parts.
    # <<-EOS
    # 
    #   <p><strong>Total Board Feet</strong> #{board_feet} board feet</p>
    #   <p><strong>Total Square Footage</strong> #{square_footage} sq. ft.</p>
    #   <p><strong>Total Parts</strong> #{total_parts}</p>
    # 
    # EOS
    
    ''
    
  end
    
  # Render the data to a CSV file.
  def render(model, data)
    
    CSVOutputFormat.new(model, data).run
    
  end

end
