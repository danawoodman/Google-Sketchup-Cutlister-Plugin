# Some utility definitions of a general scope.

# Extends class Class with a method for finding subclasses of the class.
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


# add a method to return if the current model units is metric
def metricModel? 
  
  model = Sketchup.active_model

  # Get the length Units of the active model from the unitsOptions
  # 0=inches,1=feet,2=mm,3=cm,4=m
  unit = model.options["UnitsOptions"]["LengthUnit"]
  
  return !(unit == 0 || unit == 1)
  
end
  
def modelInMeters?
  
  model = Sketchup.active_model
  
  unit = model.options["UnitsOptions"]["LengthUnit"]
  
  return unit == 4
  
end
  
# Extends class Float to provide rounding to x digits
class Float
  
  # def round_to(x)
  #   (self * 10**x).round.to_f / 10**x
  # end
  
  # def to_inch(html = false)
  #   
  #  if html
  #    
  #    self.to_html_fraction(self)
  #    
  #  else
  #    
  #    self.to_fraction(self)
  #   
  #  end
  #   
  # end
  
  def to_fraction
    
    fraction = case self.abs % 1.0
      
      when 0 then ''  # No fraction...
      
      when 1.0 / 2 then '1/2'  # One half
      
      when 1.0 / 4 then '1/4'  # One quarter
      when 3.0 / 4 then '3/4'  # Three quarters
    
      when 1.0 / 3 then '1/3'  # One third
      when 2.0 / 3 then '2/3'  # Two thirds
      
      when 1.0 / 5 then '1/5'  # One fifth
      when 2.0 / 5 then '2/5'  # Two fifths
      when 3.0 / 5 then '3/5'  # Three fifths
      when 4.0 / 5 then '4/5'  # Four fifths

      when 1.0 / 6 then '1/6'  # One sixth
      when 5.0 / 6 then '5/6'  # Five sixths

      when 1.0 / 8 then '1/8'  # One eighth
      when 3.0 / 8 then '3/8'  # Three eighths
      when 5.0 / 8 then '5/8'  # Five eighths
      when 7.0 / 8 then '7/8'  # Seven eighths

      when 1.0 / 16 then '1/16'  # One sixteenth
      when 3.0 / 16 then '3/16'  # Three sixteenths
      when 5.0 / 16 then '5/16'  # Five sixteenths
      when 7.0 / 16 then '7/16'  # Seven sixteenths
      when 9.0 / 16 then '9/16'  # Nine sixteenths
      when 11.0 / 16 then '11/16'  # Eleven sixteenths
      when 13.0 / 16 then '13/16'  # Thirteen sixteenths
      when 15.0 / 16 then '15/16'  # Seventeen sixteenths
        
    end
    
    if fraction
      
      body = case self.floor
      when -1 then '-'
      when  0 then ''
      else self.to_i.to_s
      end
      "#{body} #{fraction}"
      
    else
      
      "~ #{self.to_s}"
      
    end
    
  end
  
  def to_html_fraction
    
    fraction = case self.abs % 1.0
      
      when 0 then ''  # No fraction...
      
      when 1.0 / 2 then '&frac12;'  # One half
      
      when 1.0 / 4 then '&frac14;'  # One quarter
      when 3.0 / 4 then '&frac34;'  # Three quarters
    
      when 1.0 / 3 then '&#x2153;'  # One third
      when 2.0 / 3 then '&#x2154;'  # Two thirds
      
      when 1.0 / 5 then '&#x2155;'  # One fifth
      when 2.0 / 5 then '&#x2156;'  # Two fifths
      when 3.0 / 5 then '&#x2157;'  # Three fifths
      when 4.0 / 5 then '&#x2158;'  # Four fifths

      when 1.0 / 6 then '&#x2159;'  # One sixth
      when 5.0 / 6 then '&#x215A;'  # Five sixths

      when 1.0 / 8 then '&#x215B;'  # One eighth
      when 3.0 / 8 then '&#x215C;'  # Three eighths
      when 5.0 / 8 then '&#x215D;'  # Five eighths
      when 7.0 / 8 then '&#x215E;'  # Seven eighths

      when 1.0 / 16 then '<sup>1</sup>&frasl;<sub>16</sub>'  # One sixteenth
      when 3.0 / 16 then '<sup>3</sup>&frasl;<sub>16</sub>'  # Three sixteenths
      when 5.0 / 16 then '<sup>5</sup>&frasl;<sub>16</sub>'  # Five sixteenths
      when 7.0 / 16 then '<sup>7</sup>&frasl;<sub>16</sub>'  # Seven sixteenths
      when 9.0 / 16 then '<sup>9</sup>&frasl;<sub>16</sub>'  # Nine sixteenths
      when 11.0 / 16 then '<sup>11</sup>&frasl;<sub>16</sub>'  # Eleven sixteenths
      when 13.0 / 16 then '<sup>13</sup>&frasl;<sub>16</sub>'  # Thirteen sixteenths
      when 15.0 / 16 then '<sup>15</sup>&frasl;<sub>16</sub>'  # Seventeen sixteenths
        
    end
    
    if fraction
      
      body = case self.floor
        when -1 then '-'
        when  0 then ''
        else self.to_i.to_s
      end
      
      "#{body} #{fraction}"
      
    else
      
      "~ #{self.to_s}"
      
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

  # # remove the inch character notation "
  # def no_inch
  #   self.gsub(/["]/,"")
  # end
  # 
  # # remove the foot notation ie : '
  # def no_foot
  #   self.gsub(/[']/,"")
  # end
  
  # remove the mm notation ie :"mm"
  def no_cm
    self.gsub(/[mm]/,"")
  end
  
  # remove the cm notation ie : "cm"
  def no_mm
    self.gsub(/[cm]/,"")
  end

  # cut list plus doesn't like inch character " for inch dimensions on import - these must be
  # escaped by doubling them up
  # feet character ie: "'" is interpreted ok
  # mm characters "mm" are interpreted ok
  # cm characters "cm" are interpreted ok
  # units in m are not allowed, so these must be converted prior to this
  def to_clp
    val = self.gsub(/["]/,"\"\"")
    #val = val.gsub(/[~]/,"")
  end

  # cremove the '~' for csv text whether it is straight csv or csv for CLP
  def to_csv
    val = self.gsub(/[~]/,"")
  end

  #csv files may require units to be removed so provide a way of doing this
  # when measurements are not accurate, SU generates a ~, remove those as well
  def no_Units
    val = self.no_inch
    val = val.no_foot
    val = val.no_cm
    val = val.no_mm
    val = val.gsub(/[~]/,"")
    return val
  end

end

# #extend class integer to be able to print fixed width integers
# class Integer
#   # print an integer as a fixed width field of size width.
#   # Pads with 0's if too short, it will truncate if too long.
#   def to_fws(width)
#     val="%0#{width}d" % self.to_s
#   end
# end

#extend sketchup class Group so that we can reference the definition from which a 
# group instance has been derived. This makes it analagous to a ComponentInstance
# Sketchup groups also have a component definition but it's not
# directly accessible  so we have to start from the model definitions and search
# looking for the entity which matches ours. Once found we can use it just like
# for Component Instance
class Sketchup::Group
  def definition
    definitions = Sketchup.active_model.definitions
    definitions.each { |definition|
      definition.instances.each { |instance|
        if instance.typename=="Group" && instance == self
          return definition
        end
      }
    }  
    return nil
  end
end
