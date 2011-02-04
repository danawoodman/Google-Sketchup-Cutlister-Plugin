# Subclass teh Cutlist class so we can create a custom formatted cutlist.
class Avery5366LabelCutlist < Cutlist
  
  def initialize(model, renderer, parts, options)
    
    super(model, renderer, parts, options)
    
  end

  @display_name = "Labels (Avery 5366)"
  @description = "Create a printable web page that formats labels based on the Avery 5366 Template (2/3\" x 3 7/16\" labels, 30 per sheet)."
  
  def build
    
    data = heading("Cutlist Labels for Avery 5366", :css_location => "extensions/labels_avery_5366.css")
    
    # Only output the rows because we do not need any other information.
    data += rows(@parts.all).to_s
    
    data += footer()
    
    # puts "[Avery5366LabelCutlist.build] data:\n#{data}\n\n" if $debug
    
    # Return the results.
    data
    
  end

end

# Subclass the Renderer class so we can format parts.
class LabelRenderer < HTMLRenderer
  
  @display_name = "Labels"
  @description = "Opens a web page that can be printed on sticky labels for attaching to parts."

  def initialize(output_to_file = false)
    
    super(output_to_file)
    
  end
  
  # We don't want a page title, so override the method and make it return 
  # a blank string.
  def title
    
    ''
    
  end
  
  # We don't want a section heading, so override the method and make it return 
  # a blank string.
  def section_heading
    
    ''
    
  end
  
  def rows(parts)
    
    html = ''
    
    if parts != nil
      
      all_rows = ''
      
      parts.each { |p| 
        
        all_rows += row(p)
      
      }
      
      # puts "[LabelRenderer.rows] all_rows: #{all_rows}"
      
      html += all_rows.to_s
    
    else
      
      # TODO: Make a more useful notification here...
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
          <span class="cabinet-name">#{part['sub_assembly']}</span> - 
          <span class="part-thickness">#{part['thickness'].to_html_fraction}</span> -
          <span class="part-material">#{part['material']}</span>
        </h4>
        <p>
          <span class="part-name">#{part['part_name']}</span>
          <span class="part-size">#{part['width'].to_html_fraction} x #{part['length'].to_html_fraction}</span>
        </p>
      
      </div>
    
    EOS
    
  end
  
  # We don't want a section footer, so override the method and make it return 
  # a blank string.
  def section_footer
    
    ''
    
  end
  
end

