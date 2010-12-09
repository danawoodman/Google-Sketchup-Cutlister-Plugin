class Avery5366LabelCutlist < Cutlist
  
  def initialize(model, renderer, parts, options)
    
    super(model, renderer, parts, options)
    
  end

  @display_name = "Labels (Avery 5366)"
  @description = "Create a printable web page that formats labels based on the Avery 5366 Template (2/3\" x 3 7/16\" labels, 30 per sheet)."
  
  def build
    
    data = heading("Cutlist Labels for Avery 5366", :css_location => "labels_avery_5366.css")
    
    # Only output the rows because we do not need any other information.
    data += rows(@parts.all).to_s
    
    data += footer()
    
    puts "[Avery5366LabelCutlist] data:\n#{data}\n\n" if $debug
    
    # Return the results.
    data
    
  end

end

class LabelRenderer < Renderer
  
  @display_name = "Labels"
  @description = "Opens a web page that can be printed on sticky labels for attaching to parts."
  
  def heading(title, opts)
    
    # Default CSS location.
    css_location = 'css/master.css'
    
    # Check to see if the css_location option was passed to the heading method.
    opts.each { |key, value|
      
      # Check to see if the css_location key exists in the option hash.
      if key.to_s == "css_location"

        css_location = value

        puts "css_location: #{css_location}" if $debug

      end

    }
    
    puts "css_location for the LabelRenderer is '#{css_location}'" if $debug
    
    <<-EOS
    
      <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
      <html xmlns="http://www.w3.org/1999/xhtml"xml:lang="en" lang="en">
          <head>

              <meta http-equiv="content-type" content="text/html; charset=utf-8"/>

              <title>#{title}</title>

              <!-- Stylesheets -->
              <link type="text/css" rel="stylesheet" href="#{css_location}" media="all" />

          </head>
          <body>

    EOS
    
  end
  
  def rows(parts)
    
    html = ''
    
    if parts != nil
      
      all_rows = ''
      
      parts.each { |p| 
        
        all_rows += row(p)
      
      }
      
      puts "all_rows: #{all_rows}"
      
      html += all_rows.to_s
    
    else
      
      UI.messagebox "Sorry, there are no parts to cutlist...", MB_OK
    
    end
    
    html
    
  end
  
  # Format each row in the table.
  def row(part)
    
    # TODO: Add job name, notes, grain direction.
    <<-EOS
    
      <div class="label">
      
        <h4>
          <span class="job-name">JOBNAMEHERE</span> - 
          <span class="cabinet-name">#{part.cabinet_name}</span> - 
          <span class="part-thickness">#{part.thickness.to_s.to_inch}</span> -
          <span class="part-material">#{part.material}</span>
        </h4>
        <p>
          <span class="part-name">#{part.part_name}</span>
          <span class="part-size">#{part.width.to_s.to_inch} x #{part.length.to_s.to_inch}</span>
        </p>
      
      </div>
    
    EOS
    
  end
  
  def footer
    
    <<-EOS
       
              <p class="page-tools">
                  <input type="button" value="Print Page" class="button print" onClick="window.print();return false;" />
              </p>
      
          </body>
      </html>
    
    EOS
    
  end
  
  def render(model, data)
    
    puts "Rendering label cutlist...\n\n" if $debug
    
    puts "[LabelRenderer] data:\n#{data}\n\n" if $debug
    
    # FileOutputFormat.new(model, data, 'cutlist.html').run
    WebPageOutputFormat.new(model, data).run
    
  end
  
end
