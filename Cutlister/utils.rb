# Some utility definitions of a general scope.

# Extends class Class with a method for finding subclasses of the class. This 
# is used to populate the output and renderer lists in the Cutlister UI.
class Class
  
  def subclasses

   classes = []

   ObjectSpace.each_object do |klass|
   
     next unless Module === klass
     classes << klass if self > klass
   
   end
 
   classes
 
  end
   
end


class Array
  
  # Create a unique array from an array of hashes.
  # 
  # Since Ruby 1.8.5 does not support .uniq/.uniq! on an array of hashes, we 
  # have to hack this to make it work.
  def uniq_hash_array!
    
    if self.length == 0
      return nil
    end
    
    discard = [] 
    self.each_with_index { |element, i| 
       if (self.rindex(element) != i) then discard.unshift(i) end 
    } 
    discard.each { |d| self.delete_at(d) }
    
    self
    
  end
  
  def uniq_hash_array
    new_array = self
    new_array.uniq_hash_array!
  end
  
end
  
# Extends class Float to provide rounding to x digits
class Float
  
  def to_fraction(round_dimensions=false)
    
    fraction = case self.abs % 1.0
      
      when 0 then ''  # No fraction...
      
      when 1.0 / 2 then ' 1/2'  # One half
      
      when 1.0 / 4 then ' 1/4'  # One quarter
      when 3.0 / 4 then ' 3/4'  # Three quarters
    
      when 1.0 / 3 then ' 1/3'  # One third
      when 2.0 / 3 then ' 2/3'  # Two thirds
      
      when 1.0 / 5 then ' 1/5'  # One fifth
      when 2.0 / 5 then ' 2/5'  # Two fifths
      when 3.0 / 5 then ' 3/5'  # Three fifths
      when 4.0 / 5 then ' 4/5'  # Four fifths

      when 1.0 / 6 then ' 1/6'  # One sixth
      when 5.0 / 6 then ' 5/6'  # Five sixths

      when 1.0 / 8 then ' 1/8'  # One eighth
      when 3.0 / 8 then ' 3/8'  # Three eighths
      when 5.0 / 8 then ' 5/8'  # Five eighths
      when 7.0 / 8 then ' 7/8'  # Seven eighths

      when 1.0 / 16 then ' 1/16'  # One sixteenth
      when 3.0 / 16 then ' 3/16'  # Three sixteenths
      when 5.0 / 16 then ' 5/16'  # Five sixteenths
      when 7.0 / 16 then ' 7/16'  # Seven sixteenths
      when 9.0 / 16 then ' 9/16'  # Nine sixteenths
      when 11.0 / 16 then ' 11/16'  # Eleven sixteenths
      when 13.0 / 16 then ' 13/16'  # Thirteen sixteenths
      when 15.0 / 16 then ' 15/16'  # Seventeen sixteenths
        
    end
    
    if fraction
      
      body = case self.floor
        when -1 then '-'
        when  0 then ''
        else self.to_i.to_s
      end
      
      "#{body}#{fraction}"
      
    else
      
      if round_dimensions
        
        # Send the rounded dimension through the to_fraction method again, 
        # but this time have the rounded_dimensions setting be set to false 
        # so that it doesn't infinitely recurse if it cannot be converted to 
        # a fraction.
        f = format("%0.4f", self).to_f.to_fraction(false)
        "#{f.to_s}"
        
      else
        
        "~ #{self.to_s}"
      
      end
      
    end
    
  end
  
  def to_html_fraction(round_dimensions=false)
    
    fraction = case self.abs % 1.0
      
      when 0 then ''  # No fraction...
      
      when 1.0 / 2 then ' &frac12;'  # One half
                                  
      when 1.0 / 4 then ' &frac14;'  # One quarter
      when 3.0 / 4 then ' &frac34;'  # Three quarters
                                  
      when 1.0 / 3 then ' &#x2153;'  # One third
      when 2.0 / 3 then ' &#x2154;'  # Two thirds
                                  
      when 1.0 / 5 then ' &#x2155;'  # One fifth
      when 2.0 / 5 then ' &#x2156;'  # Two fifths
      when 3.0 / 5 then ' &#x2157;'  # Three fifths
      when 4.0 / 5 then ' &#x2158;'  # Four fifths
                                  
      when 1.0 / 6 then ' &#x2159;'  # One sixth
      when 5.0 / 6 then ' &#x215A;'  # Five sixths
                                  
      when 1.0 / 8 then ' &#x215B;'  # One eighth
      when 3.0 / 8 then ' &#x215C;'  # Three eighths
      when 5.0 / 8 then ' &#x215D;'  # Five eighths
      when 7.0 / 8 then ' &#x215E;'  # Seven eighths

      when 1.0 / 16 then ' <sup>1</sup>&frasl;<sub>16</sub>'  # One sixteenth
      when 3.0 / 16 then ' <sup>3</sup>&frasl;<sub>16</sub>'  # Three sixteenths
      when 5.0 / 16 then ' <sup>5</sup>&frasl;<sub>16</sub>'  # Five sixteenths
      when 7.0 / 16 then ' <sup>7</sup>&frasl;<sub>16</sub>'  # Seven sixteenths
      when 9.0 / 16 then ' <sup>9</sup>&frasl;<sub>16</sub>'  # Nine sixteenths
      when 11.0 / 16 then ' <sup>11</sup>&frasl;<sub>16</sub>'  # Eleven sixteenths
      when 13.0 / 16 then ' <sup>13</sup>&frasl;<sub>16</sub>'  # Thirteen sixteenths
      when 15.0 / 16 then ' <sup>15</sup>&frasl;<sub>16</sub>'  # Seventeen sixteenths
        
    end
    
    if fraction
      
      body = case self.floor
        when -1 then '-'
        when  0 then ''
        else self.to_i.to_s
      end
      
      "#{body}#{fraction}&rdquo;"
      
    else
      
      if round_dimensions
        
        # Send the rounded dimension through the to_html_fraction method again, 
        # but this time have the rounded_dimensions setting be set to false 
        # so that it doesn't infinitely recurse if it cannot be converted to 
        # a fraction.
        f = format("%0.4f", self).to_f.to_html_fraction(false)
        "#{f.to_s}"
        
      else
        
        "~ #{self.to_s}&rdquo;"
      
      end
      
    end
    
  end
  
end

# Extend class String to be able to convert the string to an html compliant string
# as well as some manipulations required for CutList Plus compatibility and other string
# filters.
class String
  
  # This will html-ise a string so that we don't have problems displaying in html
  # returns a copy of the string with problematic characters replaced by escape sequences.
  def to_html
    
    val = self.gsub(/[&]/, "&amp;")  # Convert ampersands first, so we don't convert them later.
    val = val.gsub(/[ ]/, "&#32;")
    val = val.gsub(/[']/, "&#39;")
    val = val.gsub(/["]/, "&quot;")
    val = val.gsub(/[<]/, "&lt;")
    val = val.gsub(/[>]/, "&gt;")
    val = val.gsub(/[-]/, "&#45;")
    
    return val
    
  end 
  
end
