load 'cutlist/cutlistutl.rb'
load 'cutlist/layout.rb'
load 'cutlist/boards.rb'
load 'cutlist/parts.rb'
load 'cutlist/drivers.rb'
load 'cutlist/gui.rb'
load 'cutlist/display.rb'
load 'cutlist/renderers.rb'

#-----------------------------------------------------------------------------
# Reporter class
# This class does the main work of deriving the components from the user selection of the given model, 
# splitting into solid wood components and sheet good components 
# ( and hardware or other 'parts') and then producing the cutlist display in the requested output format
# All methods are private.
# There is only 1 'entry point' which is sketchupInit which is called when an action is requested from the gui
#-----------------------------------------------------------------------------
class Reporter
  
  cutlist_Default_Options = {
    :compactList=> true,
    :listAllSorted => false,
    :linearFeet => true,
    :outFileUsed => true,
    :outFileName => "CutList.csv",
    :clpFileUsed => true,
    :clpFileName => "CutListPlusImport.csv",
    :printPage => false,
    :showComps => true,
    :showSheet => true,
    :showParts => true,
    :forceBoardFeet => false,
    :layout => false,
    :su5 => false,
    :partWords => ["part"],
    :sheetWords => ["sheet"],
    :svgLayout=>false
    }
    
  layout_Default_Options ={
    :fourq => false,
    :fiveq => false,
    :sixq => false,
    :eightq => false,
    :tenq => false,
    :nominalMargin => 0,
    :nominalOut =>false,
    :board4w=>false,
    :board6w=>true,
    :board8w=>false,
    :board10w=>false,
    :board12w=>false,
    :board2l=>false,
    :board4l=>false,
    :board6l=>false,
    :board8l=>true,
    :board10l=>false,
    :board12l=>false,
    :sheet2w=>false,
    :sheet4w=>true,
    :sheet5w=>false,
    :sheet2l=>false,
    :sheet4l=>false,
    :sheet5l=>false,
    :sheet8l=>true,
    :nominalWidth=>true,
    :kerfSize=> 2.inch/16,
    :splitWideParts=>true,
    :splitThickParts=>false,
    :layoutRuleA=>true,
    :layoutRuleB=>true,
    :layoutByMaterial=>false,
    :displayUnplacedParts=>true,
    :useSawKerf=>true,
    :sawKerfSize=>0,
    :sawKerfUnits=>"8th"
  }
  
  @@options = {
  :cutlist_Options => cutlist_Default_Options,
  :layout_Options => layout_Default_Options
  }
  
  ##
  # This entry point method is called by the interactive GUI ( html) configurator
  ##
  def sketchupInit(cutlist_options, layout_options)
    # merge user selected options with the defaults to get the working set for this session
    @@options[:layout_Options].merge!(layout_options)
    @@options[:cutlist_Options].merge!(cutlist_options)
    
    # determine the flavor of the model, metric or inches
    @metric = metricModel?
    
    # sets whether or not we ask for permission to update group instances found in the model the first time we encounter 
    # a case of it. Leave off for now. This means
    # that it won't ask and so permission is never granted. This feature might be useful but potentially confusing because
    # it alerts to a sketchup internal condition and the user may not realize the implications of answering one way or another.
    # (If you modify a group instance, it automatically is made unique so that the group definition no longer applies to it. If you then
    # wanted to make a change to the group definition, you would have to make the same change to ALL instances, thus losing some
    # of the advantages of it being in a group in the first place.
    @askFirstTime = false
    
    # Determine the units to use for volume measurements in the output
    # If metric units selected, then use metric volume measurements ( ie cu.m.)
    # If metric units selected but forceBoardFeet is on, then use board feet
    # If Imperial measure, then always use board feet
    @volumeMeasureInMetric = (@metric && !@@options[:cutlist_Options][:forceBoardFeet])

    # establish specific sets of options, based on layout and cutlist options, one for boards and one for sheets
    setBoardOptions()
    setSheetOptions()
    
    # create an input board list - empty for now until we create an interface for it
    @inBoardList = BoardList.new()
                       
    # do the work of the reporter class
    main()
  end # def Reporter::sketchupInit
  
  def setBoardOptions
    setBoardThicknessOptions
    setBoardWidthOptions
    setBoardLengthOptions
    @boardOptions = [@boardLengthOptions,@boardWidthOptions,@quarter, @@options[:layout_Options][:nominalWidth]]
  end

  def setSheetOptions
    setSheetWidthOptions
    setSheetLengthOptions
    # sheets always use nominalWidth, so set that option true always
    # sheets don't use quarter options, so set up a dummy one for sheets with all false
    @sheetQuarter = [false,false,false,false,false]
    @sheetOptions = [@sheetLengthOptions,@sheetWidthOptions,@sheetQuarter,true]
  end
  
  def setBoardThicknessOptions
    #produce an array with all four options placed in it in order
    @quarter = [ @@options[:layout_Options][:fourq], 
                       @@options[:layout_Options][:fiveq], 
                       @@options[:layout_Options][:sixq], 
                       @@options[:layout_Options][:eightq],
                       @@options[:layout_Options][:tenq] ]
  end
  
  def setBoardWidthOptions
    # produce an array with the different widths available
    # this construct makes it easier to iterate over the available options
    # convert lengths, which are in feet, to inches, so that all units are the same internally.
    @boardWidthOptions = Array.new
    @boardWidthOptions.push(4) if @@options[:layout_Options][:board4w]
    @boardWidthOptions.push(6) if @@options[:layout_Options][:board6w]
    @boardWidthOptions.push(8) if @@options[:layout_Options][:board8w]
    @boardWidthOptions.push(10) if @@options[:layout_Options][:board10w]
    @boardWidthOptions.push(12) if @@options[:layout_Options][:board12w] 
  end
  
  def setBoardLengthOptions
    # produce an array with the different lengths available
    # this construct makes it easier to iterate over the available options
    @boardLengthOptions = Array.new
    @boardLengthOptions.push(2*12) if @@options[:layout_Options][:board2l]
    @boardLengthOptions.push(4*12) if @@options[:layout_Options][:board4l]
    @boardLengthOptions.push(6*12) if @@options[:layout_Options][:board6l]
    @boardLengthOptions.push(8*12) if @@options[:layout_Options][:board8l]
    @boardLengthOptions.push(10*12) if @@options[:layout_Options][:board10l]
    @boardLengthOptions.push(12*12) if @@options[:layout_Options][:board12l] 
  end

  def setSheetWidthOptions
    @sheetWidthOptions = Array.new
    # If the sketchup model is in metric units, then use standard metric equivalent sizes for the plywood but store in inches
    if ( metricModel? )
      @sheetWidthOptions.push(610/25.4) if @@options[:layout_Options][:sheet2w]
      @sheetWidthOptions.push(1220/25.4) if @@options[:layout_Options][:sheet4w]
      @sheetWidthOptions.push(1525/25.4) if @@options[:layout_Options][:sheet5w]
    else
      @sheetWidthOptions.push(2*12) if @@options[:layout_Options][:sheet2w]
      @sheetWidthOptions.push(4*12) if @@options[:layout_Options][:sheet4w]
      @sheetWidthOptions.push(5*12) if @@options[:layout_Options][:sheet5w]
    end
  end

  def setSheetLengthOptions
    @sheetLengthOptions = Array.new
     # If the sketchup model is in metric units, then use standard metric equivalent sizes for the plywood but store in inches
    if ( metricModel? )
      @sheetLengthOptions.push(610/25.4) if @@options[:layout_Options][:sheet2l]
      @sheetLengthOptions.push(1220/25.4) if @@options[:layout_Options][:sheet4l]
      @sheetLengthOptions.push(1525/25.4) if @@options[:layout_Options][:sheet5l]
      @sheetLengthOptions.push(2440/25.4) if @@options[:layout_Options][:sheet8l]
    else
      @sheetLengthOptions.push(2*12) if @@options[:layout_Options][:sheet2l]
      @sheetLengthOptions.push(4*12) if @@options[:layout_Options][:sheet4l]
      @sheetLengthOptions.push(5*12) if @@options[:layout_Options][:sheet5l]
      @sheetLengthOptions.push(8*12) if @@options[:layout_Options][:sheet8l]
    end
  end
  
  # does the main work of the reporter class ie: this is the mainline for the cutlist plugin
  def main    
    # derive the component set required for cutlist from this model. Method components() establishes the working cutlist database
    if ( components() != nil )
      # produce a layout if requested. Layout() creates the necessary database for layout output based on the cutlist database
      if(@@options[:cutlist_Options][:layout] || @@options[:cutlist_Options][:svgLayout] )
        layout()
      end
      # produce the requested cutlist output in the requested formats
      output()
    end
  end
  
  def layout
      # Note:We reference the show parts and show sheet parts options here instead of on the output for efficiency. cutting down on the
      # generation of layout speeds up the output. The output will just display whatever was generated here.
      # determine if we need to create a layout for solid parts
      @unplacedPartsList = CutListPartList.new
      if !@solidPartList.empty? && @@options[:cutlist_Options][:showComps]
        # Split the list of parts into categories to be used for layout based on the selection options
        # make a copy of the partLists object because the layout engine is destructive
        solidPartList = @solidPartList.deep_clone
        solidPartPreParser = SolidPartPreParser.new(solidPartList,@inBoardList,@boardOptions,@@options[:layout_Options],@volumeMeasureInMetric)
        @listOfSolidPartsLists, unplacedPartsList = solidPartPreParser.run
        @unplacedPartsList +(unplacedPartsList) if unplacedPartsList != nil
        
        # for each category of solid parts, layout on as many boards as required
        @layoutBoards = Array.new
        @listOfSolidPartsLists.each { |solidPartList|
          solidPartLayoutEngine = BestFitLayoutEngine.new(solidPartList,@inBoardList,@boardOptions,@@options[:layout_Options],@volumeMeasureInMetric)
          layoutBoards, unplacedPartsList = solidPartLayoutEngine.run
          @layoutBoards += layoutBoards if layoutBoards != nil
          puts "Boards Added=" + @layoutBoards.size.to_s if $verbosePartPlacement
          @unplacedPartsList +(unplacedPartsList) if unplacedPartsList != nil
          puts "Unplaced Solid Parts during layout=" + unplacedPartsList.count.to_s if  $verbosePartPlacement
        }
      end
      # determine if we need to create a layout for sheet parts
      if !@sheetPartList.empty? && @@options[:cutlist_Options][:showSheet]
        # Split the list of sheet parts into categories to be used for layout based on the selection options
        sheetPartList = @sheetPartList.deep_clone
        sheetPartPreParser = SheetPartPreParser.new(sheetPartList,@inBoardList,@sheetOptions,@@options[:layout_Options],@volumeMeasureInMetric)
        @listOfSheetPartsLists,  unplacedPartsList = sheetPartPreParser.run
        @unplacedPartsList +(unplacedPartsList) if unplacedPartsList != nil
        
        # for each category of sheet parts, layout on as many boards as required
        @layoutSheets = Array.new
        @listOfSheetPartsLists.each { |sheetPartList|
          sheetPartLayoutEngine = BestFitLayoutEngine.new(sheetPartList,@inBoardList,@sheetOptions,@@options[:layout_Options],@volumeMeasureInMetric)
          layoutSheets, unplacedPartsList = sheetPartLayoutEngine.run
          @layoutSheets += layoutSheets if layoutSheets != nil
          puts "Sheets Added=" + @layoutSheets.size.to_s if $verbosePartPlacement
          @unplacedPartsList +(unplacedPartsList) if unplacedPartsList != nil
          puts "Unplaced Sheet Parts during layout=" + unplacedPartsList.count.to_s if  $verbosePartPlacement
        }
      end
  end
        
  ### Get the material assigned faces within a component if it is not assigned at
  ### the component level
  def getMaterial(component)
    bits = nil
    if(component.typename == "ComponentInstance")
      bits = component.definition.entities
    elsif(component.typename == "Group")
      bits = component.entities
    end ##if

    for f in bits
      if f.typename == "Face"
        materialClass = f.material
        if(materialClass!=nil)
          return materialClass.name
        end
      end
    end
    return "Not assigned"
  end ##getMaterial

  # check if this component is a group with an instance definition
  # if so, then we can derive a name from the original definition if there is one  
  def getGroupCopyName(entity)
    name = ""
    definitions = Sketchup.active_model.definitions
    definitions.each { |definition|
      definition.instances.each { |instance|
        if instance.typename=="Group" && instance == entity
          #now go through this definition and see if there is an instance with a name, return it if found
          definition.instances.each { |i|
            if ( i.name != "" )
              name = i.name
              # now let's do it again but actually set the name of all instances to the one found if user oks this
              if @askFirstTime
                if ( UI.messagebox("Copied group parts found with no name. Ok to set to the same name as the master copy?",  MB_OKCANCEL) == 1 )
                  @okToCopyName = true
                else
                  @okToCopyName = false
                end
                @askFirstTime = false
              end
              if @okToCopyName
                definition.instances.each { |i| i.name = name }
              end
              break
            end
          }
          return name
        end
      }
    }    
    return name
  end
  
  #-----------------------------------------------------------------------------
  # The getSubComponent method is called recursively to derive the fundamental component parts of the model from all
  # components and groups in the selection.
  # returns true if a component level has components
  # Adds components to our component data base as it encounters them and sorts them into hardware parts, sheet goods or solid goods
  # If a component has no sub-components below it, then it must be an elemental part and it is added.
  # Top level components are not added if they have sub-components ( this is because the bounding box of the 
  # top level components encompasses all of its subcomponents and leads to incorrect cutlists)
  # Top level components have sub-components if it or any of its sub-components have sub-components. In other words
  # sub-componentness is transitive.
  # Basically this is a search for all of the basic components. The only exception is for hardware parts where we
  # return the highest level ( on the assumption that the cutlist is not interested in the sub-components of a hardware part)
  # For example, it's not relevent to know that a castor wheel is made up up a wheel, a metal housing, an axle, nuts, etc, at least not in the cutlist context
  # SubAssemblyName is the name of the parent Component, so that we can record which subassembly a part belongs to
  # When this method is first called, the subAssemblyName is the project, as everthing belongs to the project by default.
  #-----------------------------------------------------------------------------
  def getSubComponents(entityList, level, subAssemblyName)
    puts "checking level=" + level.to_s if $verboseComponentDiscovery
    model = Sketchup.active_model
    selection = model.selection
    # the levelHasComponents flag is used to indicate if we have found any parts at this level
    levelHasComponents  = false
    for c in entityList
      inSelection = selection.contains? c
      #Sub components do not appear as part of the selection so let them through but only look at visible sub-components
      if ( (inSelection || level>1) && c.layer.visible?)
        
        if c.typename == "ComponentInstance" || c.typename == "Group"
          # get the name of the component or group or try the inferred name based on its parent if it is a group with no name
          compName = nil
          if(c.typename == "ComponentInstance")
            compName = c.definition.name
            puts "component instance with definition name=" + compName.to_s if $verboseComponentDiscovery
          elsif(c.typename == "Group")
            compName = c.name
            puts "group with name=" + compName.to_s if $verboseComponentDiscovery
            if (compName == nil || compName == "" )
              #let's see if this is a copy of a group which might already have a name
              compName = getGroupCopyName(c)
              if ( compName != nil && compName != "" )
                puts "group had no name but is assigned name=" + compName.to_s + " based on its parent" if $verboseComponentDiscovery
              end
            end
          end ##if
          
          #puts "element: " " type=" + c.typename.to_s + " inSelection=" + inSelection.to_s + " level=" + level.to_s + " visible=" + c.layer.visible?.to_s if $verboseComponentDiscovery
          
          # get the material name for this part
          partMaterialClass = c.material
          if(partMaterialClass==nil)
            partMaterial = getMaterial(c)
          else
            partMaterial = partMaterialClass.name
          end
          
          # compare the 'part' words entered by the user to the entity name or to the material name
          # to find the non cutlist parts
          # If this is a hardware part, then we are done with this part
          
          if (isPartOrSheet( @@options[:cutlist_Options][:partWords], partMaterial ) ||
              isPartOrSheet( @@options[:cutlist_Options][:partWords], compName) )
            @partList.add(compName)
            puts "adding part name=" + compName.to_s + " level=" + level.to_s  + " as a hardware part since material or name matched"  if $verboseComponentDiscovery
            puts "+++++++++++++++++++++++++++" if $verboseComponentDiscovery
            # since a part was added, mark this level as having components
            levelHasComponents = true
            next   #move on to the next part at this level
          end
          
          # if it is not a hardware part, then for this component or group, go a level deeper to see if it has sub-components
          subList = nil
          if(c.typename == "ComponentInstance")
            subList = c.definition.entities
          elsif(c.typename == "Group")
            subList = c.entities
          end ##if
          
          # go one level deeper if we found a type of part that might have subparts which we want to add to our list
          # Note: this calls itself recursively until there are no sub-components at the particular level we are looking at
          # compName is the name of the current part which we are exploring to a deeper level ie: the subassembly name
          # Even if this part is ultimtely not added ( because it has sub-conponents) we can record which sub-assembly it belongs to its chold parts
          hasSubComponents = getSubComponents(subList, level+1, compName) 
          if (!hasSubComponents )
           puts "adding part name=" + compName.to_s + ",subAssembly=" + subAssemblyName.to_s + " level=" + level.to_s  + " since level=" + (level+1).to_s + " has no subcomponents" if $verboseComponentDiscovery
           puts "+++++++++++++++++++++++++++" if $verboseComponentDiscovery
            ### allows names with - + at start etc
            name = " "+compName
            
            ### If no name is given generate one based on size so that same size unnamed object get grouped together.
            if(name== " ")
              name = "noname"
            end 

            materialClass = c.material
            if(materialClass==nil)
              material = getMaterial(c)
            else
              material = materialClass.name
            end

            # compare the 'sheet' words entered by the user against the material name
            # if there is a match then this selected entity becomes a sheet good object
            # Everything else is a solid part 
            if ( isPartOrSheet( @@options[:cutlist_Options][:sheetWords], material ) ||
                 isPartOrSheet( @@options[:cutlist_Options][:sheetWords], name ) )
              sheetPart = SheetPart.new(c, name, subAssemblyName, material, @volumeMeasureInMetric)
              # add to the list
              @sheetPartList.add( sheetPart )
            else
              solidPart = SolidPart.new(c,
                                        name, subAssemblyName, material, 
                                        @@options[:layout_Options][:nominalMargin], 
                                        @quarter,
                                        @@options[:layout_Options][:nominalOut], 
                                        @volumeMeasureInMetric)
              # add to the list
              @solidPartList.add( solidPart )
            end  ##if
          else
            puts "skipping partname=" + compName.to_s + " at level=" + level.to_s  + " since level=" + (level+1).to_s + " has subcomponents" if $verboseComponentDiscovery
            puts "--------------------------" if $verboseComponentDiscovery
          end
          # if the level below had no subcomponents, then we just added this part at this level, so mark this level as having components
          # if the level below us had subcomponents, then so must this one by transitiveness, even if none specifically
          # existed at this level ( there could be nested top level components), so in either case we set the level to have components
          levelHasComponents = true
        #else
          #puts "skipping entityList element: " " type=" + c.typename.to_s + " inSelection=" + inSelection.to_s + " level=" + level.to_s + " visible=" + c.layer.visible?.to_s if $verboseComponentDiscovery
        end
      #else
        #puts "skipping entityList element: " " type=" + c.typename.to_s + " inSelection=" + inSelection.to_s + " level=" + level.to_s + " visible=" + c.layer.visible?.to_s if $verboseComponentDiscovery
      end#if
    end#for c
    puts "returning levelHasSubcomponents=" + levelHasComponents.to_s + " for level=" + level.to_s if $verboseComponentDiscovery
    return levelHasComponents
  end #getSubComponents

  #-----------------------------------------------------------------------------
  #  Checks to see if component is a Part or Sheet 
  # Make this so it is not case sensitive, so you don't have to enter all possibilities of the same word, capitalized and not
  # Also support special characters similar to Google search to allow specific exclusion of words
  # "-" character ahead of the word means do not include matches on this word ( for example -partition for a part word
  # means that a component named 'partition' should not be considered a part but rather a component which should be 
  # included in the cutlist).
  # The '-' must immediately precede the word, no spaces
  #-----------------------------------------------------------------------------
  def isPartOrSheet( inList, compName )
    @found = false
    @exclusionFound  = false
    inList.each do |p|
      matchWord = p
      
	    # check for the exclusion syntax ( a negative in front of the word)
      exclude = ( (p =~ /^-/)  != nil )
      
      # if  nothing follows the -, then ignore this list word - wrong syntax
      next if ( $' == '' && exclude )
      
      # if the '-' matches the first character, use the part which didn't match as the search string
      matchWord = $' if exclude
      
      # see if the list word matches anywhere in the component name  - case insensitive
      if ( (compName.index(/#{matchWord}/i)) != nil  )
          # Exclusions trump inclusions no matter where they are placed in the list
          if ( exclude )
            @exclusionFound = true
            @found = false
          end
          @found = true if ( !@exclusionFound )
      end
    end # end do loop
    # return the result of the search through all the words. 
    return @found
  end ## end isPartOrSheet
  
  #-----------------------------------------------------------------------------
  # Invert the current selection
  # Takes a current model, changes the selection to be the complete inverse of the
  # current selection and returns the modified model
  #-----------------------------------------------------------------------------
  def invert_selection!(model)
        ss = model.selection
        model.entities.each {|e| ss.toggle(e)}
        return model
  end

  #-----------------------------------------------------------------------------
  # Determine the selection from the model ( or force select all if none was selected)
  # and then decompose the selection to a list of components to be included in cutlist,
  # sheet goods and other parts
  # Either pops up an error to the user and returns or if components found, 
  # when done, there is a list of components in @solidPartlist, sheet goods in @sheetPartlist
  # and parts in the @partList
  #-----------------------------------------------------------------------------
  def components    
    # create a new parts list
    @partList = PartList.new()
    
    # create the new Solid part list
    @solidPartList = SolidPartList.new()
    
    # create the new Sheet part list
    @sheetPartList = SheetPartList.new()
    
    # select the current model
    model = Sketchup.active_model
    
    # get the parts of the model selected
    selection = model.selection
    # start undo...
    model.start_operation "undo"

    # If the current selection is empty, then assume that the entire  model is to be selected.
    # toggle the selection to select all, if still empty, then  display a message
    if ( selection.empty? )
      # try selecting all
      # confirm with the user that this is ok
      if ( UI.messagebox("Nothing was selected from the model.\nDo you want to select all visible? ",  MB_OKCANCEL) == 1 )
        
        # inverse the empty selection to select all
        model = invert_selection!(model)
        @selection_inverted = true

        # get the selection from the model again
        selection = model.selection
        
        #remove any entities from the selection which are not visible
        selection.each { |entity| selection.toggle( entity) if !entity.layer.visible? }
        
        # if it's still empty, then there must be nothing in the model.
        if ( selection.empty? )
          UI.beep
          UI.messagebox("Your model is empty or no entities are visible.\nNo Cutlist generated.")
          return nil
        end
      else
        # user cancelled from the select all request
        return nil
      end
    end

    entities = model.entities
    @mname = model.title

    # check model has a directory path, so we know where to store the output 
    mpath = model.path
    puts "Model path=" + model.path.to_s
    if mpath == ""
      UI.beep
      UI.messagebox("You must save the 'Untitled' new model \nbefore making a Component Report !\nNo Cutlist generated.")
      return nil
    end
     
    # now get the actually directory from the path, so we can put our files in the same directory.
     
    @mpath = File.dirname(mpath)
    puts "directory= " + @mpath.to_s

    ### show VCB and status info...
    Sketchup::set_status_text(("CUT LIST GENERATION..." ), SB_PROMPT)
    Sketchup::set_status_text(" ", SB_VCB_LABEL)
    Sketchup::set_status_text(" ", SB_VCB_VALUE)

    #main work of deriving the components from the selection of the model. This updates @solidPartList and @sheetPartList the components and sheet good lists respectively
    puts "Component Discovery start ---->" if $verboseComponentDiscovery
    #getSubComponents(entities,1, @mname)
    #DEBUG
    # pass the selection, not the entities
    getSubComponents(selection,1, @mname)
    #DEBUG
    puts "Component Discovery end <----" if $verboseComponentDiscovery
    
    # if no components selected or no parts then exit...
    if ( @solidPartList.empty? && @sheetPartList.empty? && @partList.empty?)
      UI.beep
      UI.messagebox("No Components found in your model.\nYou must create a Component from your selection.\nClick on Help for more info.\nNo Cutlist will be generated.")
      return nil
    end
    
    #finally sort the solid component list and sheet list if the option was selected
    if @@options[:cutlist_Options][:listAllSorted]
      @solidPartList.sort
      @sheetPartList.sort
    end
    
        # commit undo...
    model.commit_operation

  end # components
  
def output
    ### HTML output ###
    if(@@options[:cutlist_Options][:printPage])
      cutlistHtml = HtmlOutputDriver.new(@@options[:cutlist_Options][:compactList],
                                                       @@options[:cutlist_Options][:showComps],
                                                       @@options[:cutlist_Options][:showSheet],
                                                       @@options[:cutlist_Options][:showParts],
                                                       @volumeMeasureInMetric,
                                                       @solidPartList,
                                                       @sheetPartList,
                                                       @partList,
                                                       @mname)
      cutlistHtml.run
    end ## if

    ### File output ###
    if(@@options[:cutlist_Options][:outFileUsed])
      cutlistCsvFile = FileOutputDriver.new(@@options[:cutlist_Options][:compactList],
                                                         @@options[:cutlist_Options][:showComps],
                                                         @@options[:cutlist_Options][:showSheet],
                                                         @@options[:cutlist_Options][:showParts],
                                                         @volumeMeasureInMetric,
                                                         @solidPartList,
                                                         @sheetPartList,
                                                         @partList,
                                                         @mname,
                                                         @mpath,
                                                         @@options[:cutlist_Options][:outFileName])
      cutlistCsvFile.run
    end ## if

    ### CutListPlus output ###
    if(@@options[:cutlist_Options][:clpFileUsed])
      cutlistClpFile = ClpFileOutputDriver.new(@@options[:cutlist_Options][:compactList],
                                                            @@options[:cutlist_Options][:showComps],
                                                            @@options[:cutlist_Options][:showSheet],
                                                            false,
                                                            @volumeMeasureInMetric,
                                                            @solidPartList,
                                                            @sheetPartList,
                                                            @partList,
                                                            @mname,
                                                            @mpath,
                                                            @@options[:cutlist_Options][:clpFileName])
      cutlistClpFile.run
    end ## if
    
    if(@@options[:cutlist_Options][:layout])
      @unplacedPartsList = nil if !@@options[:layout_Options][:displayUnplacedParts]
      cutlistLayoutHtml = HtmlLayoutDriver.new(@layoutBoards,
                                                               @layoutSheets,
                                                               @unplacedPartsList,
                                                               @mname)
      cutlistLayoutHtml.run
    end
    
    if(@@options[:cutlist_Options][:svgLayout])
      @unplacedPartsList = nil if !@@options[:layout_Options][:displayUnplacedParts]
      cutlistSvgLayoutHtml = SvgLayoutDriver.new(@layoutBoards,
                                                                    @layoutSheets,
                                                                    @unplacedPartsList,
                                                                    @mname,
                                                                    @mpath)
      cutlistSvgLayoutHtml.run
    end

  end#def output

end#class Reporter
