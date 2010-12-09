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
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end
end

# Extend class String to be able to convert the string to an html compliant string
# as well as some manipulations required for CutList Plus compatibility and other string
# filters.
class String
  
  def to_inch
    
    # TODO: Convert a string to inch dimensions (including fractions).
    val = self # Take the decimals and convert to a fraction.
    val = "#{val}\""
    
    val
    
  end
  
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
