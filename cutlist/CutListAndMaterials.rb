#-----------------------------------------------------------------------------
#
# Copyright 2006-2010 daltxguy, Vendmr
# Based on CutList.rb, Copyright 2005, CptanPanic
#
# Permission to use, copy, modify, and distribute this software for
# any purpose and without fee is hereby granted, provided something the above
# copyright notice appear in all copies.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#-----------------------------------------------------------------------------
#
# Name        : CutListAndMaterials.rb
#
# Type        : Tool
#
# Version    : 4.1.0
#
# Description : Makes a cutlist based on all selected components in model.
#
# Menu Item   : Plugins -> CutList
# Context-Menu: None
#
# Authors      : <steve racz> daltxguy@gmail.com - since v3.2a
#                    <michael robinson> vendmr@yahoo.com - up to v3.2
#                   
#
# Currently maintained by :  <steve racz> daltxguy@gmail.com
#
# Usage       : Note: the following description higlights some of the key features. Help is available on each item
#                  of the configuration menu once the cutlist plugin has been started.
#                Call script using Plugins menu, and file name *-CutList.cvs is created in the model's
#               folder.  It is readable by text editors, and cutlist programs like CutList Plus.
#               This script uses bounding boxes to ascertain the dimensions of parts within the user
#               selection.  Only components, groups and components within components are recorded.  Ensure that
#               the component axes are adjusted to the component to give the smallest bounding box to
#               get accurate sizes.  A component which has been thusly created and then rotated will be correctly calculated
#               based on its original axes aligned bounding box. ( In other words, the best way to create a part which is not axes
#               aligned is to create one which is and then rotate it )
#               Volumes are given in board foot or in cu.m. depending on the units used for the model. You can force board 
#               volumes to be in board feet even if the model is in metric units using the 'force board feet' option. This is useful
#               for using metric to build the model but to order wood when the local market ueses imperial.
#               Any component whose name contains the string Part or part will not be treated as wood
#               for the cutlist but as a hardware part and it will be counted.
#               Any component that has a material whose name contains the word sheet or Sheet will
#               be treated as sheet material in a separate list.  Sheet material is calculated in
#               square feet rather than board feet.
#
# Installation: Instructions are available at http://lumberjocks.com/jocks/daltxguy/blog/5143
# Forum : http://lumberjocks.com/topics/9435
#
# Additional info: Available at http://steveracz.com/joomla/content/view/45/1/
#
# Date last modified        : Aug 2009
#
# Version     :        1.0                        Initial Release.
#             : 2.0         Added recognition of hardware parts
#             : 2.5         Works with groups, recognizes sheet material
#             : 2.6         Changed lists to compact display with quantity column
#             : 3.0         Added a web user interface, major code refactor, CutListPlus support,
#                           metric support
#             : 3.1         Fixed web display of feet.  Unique names given to unnamed components.
#             : 3.2         Added total length for components in compact view.
#             : 3.2a        Fixed CutListPlus output, Add Force Bd Ft measure ( overrides volume in bd ft even if metric measure used )
#             : 3.3         Added nominal size support.
#             : 4.0        Added new functionality to layout boards. Major code refactor.
#                           Added 'select all components' request if nothing selected by user, Restructured and tidied classes and ruby code
#                            Added tabs to the config html. Renamed name which appears on plugin menu and nested items. Make parts and sheet keyword searches case insensitive. 
#                            Add syntax to exclude words from the search. Fix html error with material names with '<','>' characters. Cutlist solid parts and
#                             sheet parts are now objects instead of arrays. All Cutlist part measures are stored in inches and converted only when displaying
#                             Float class extended to introduce simple syntax for rounding. Rounding is only done on output.
#                             Now displays (or prints) only non-nil lists ie:if no sheet parts found, then only components and parts are displayed etc.
#             : 4.0.1       Add support for SVG output for the layout.
#             : 4.0.2      Add support for Mac devices - change forward slashes to backslashes for file paths, eliminate \n
#             : 4.0.3      Add support for scaled components and groups.
#             : 4.0.4      Fix for layout output when only sheet good components are present.
#             : 4.0.5      Split SVG layout into multiple files when layout spans multi pages. Fix mpath to be the directory where the model is located so files
#                            are written to a known location ie: the same diretory as the model.
#             : 4.0.6      Fix accuracy of metric volume. Change cu.cm to cu.m - a more common measure in metric.
#                            In non-english world, measures are written  as 1.000,00 compared with 1,000.00. Ie: meaning of decimals/commas
#                            are reversed, therefore CSV files need to have a different delimiter than commas, use ";" instead.
#                            Add dedicated output driver for CutList PLus to better match the import requirements for CutList Plus 2009
#             : 4.0.7      Improve SVG pagination. 4x8 sheets come out in separate pages now.
#                            Hardware parts on now matched on either their material name or their part name using the 'part words'.
#                            Fixed bug in component selection: If a part appeared in a nested component, sometimes the top level component would get included in the cutlist
#                            Layout only displays selected set of components now. Previously the component/sheet 'type' setting was ignored.
#                            Add model name to the cutlist output and each page of the layout.
#                            'Select ALL' when prompted by the plugin, ( if nothing was selected) will now select only the visible components, allowing layers to be excluded from the cutlist
#                               In addition, the getSubComponents parser will select only visible sub-components
#                            Minor field naming cleanup for partwords/sheetwords in cutlist.html. No functional change.
#                            Some field names on the menu have been changed to hopefully make what they mean more intuitive
#             : 4.1.0       New interface for custom sized boards or sheets - tbd
#                            Ability to specify kerf size  for the layout - ok
#                            Ability to specify rough cut margin ( how much extra board to leave for each piece for planing, etc ) - can be done kerf and margin - ok
#                            Fixes to layout optimization to prevent fragmentation and therefore inefficient layout - tbd
#                            New tick box to indicate that sheet layout usage should also be specified in area as well as volume - tbd
#                            For CutList Plus users, if material contains key word "primary" then it is specified as a primary material - tbd
#                            Add project name to the html output page, same as for the SVG file - ok
#                            Provide a new 'project file' output which combines all output into a set of SVG files, suitable for printing - tbd
#                            Provide a new Rough cutlist if requested which specifies cut list of rough cut boards rather than final sizes - tbd
#                            Plywood sizes are calculated as metric equivalents when model is metric, not imperial standards - ok
#                            Fix bug  -  not all parts  were being found when a part was in a nested component - ok
#			     Order of parts listed is now alphabetical by part name - this was a degradation by previous changes and this functionality is restored -ok
#			     Alignment of CutListPlus output in terms of sketchup units used and CLP units/import file expected for more seamless CLP integration - ok
#			     Support for 5'x5' sheets - ok
#                            Internationalization - tbd
#                            Print view should be in black and white to save toner and color on printers - ok (partial-more can be done here)
#                            SVG output should open new window with clickable links, possible also displaying the output..? - tbd
#                            New option for layout to optimize cutting, not necessarily efficiency of board use - tbd
#                            Allow use of & in part names - ok
#                            Component/subcomponent order - ok ( see 4.1.0.6)
#                            New method of part numbering/labeling - tbd
#                            Display labels with arrows for small parts instead of part names in center - print ledger - tbd
#                4.1.0.4     Part numbering should ensure sort by part number puts it in numeric order - change number to all double digits (or triple?) - ok
#                4.1.0.5     Csv and CLP files should exclude the '~' from measurements but html display should retain it ( as a visual that a part is inaccurate) - ok
#                            Parts should only be compacted if they are truly the same ( same name, same dimensions, same material) - affects compact list, CLP - ok
#                4.1.0.6     File organization refactor. Split into multiple files. Add cutlist.rb to plugins directory, all other files are not in cutlist directory - ok
#                            Add the much awaited ability to list parts by sub-assembly. Compact list does not show sub-assemblies. GUI label changes - ok
#-----------------------------------------------------------------------------

require 'sketchup.rb'
load 'cutlist/reporter.rb'  # this is the 'main' and is invoked from cutlist.rb in the plugins directory


# determine amount of debugging output to the ruby console
$verbose1 = false # minimal progress tracking
$verbose = false # the whole enchilada - slows down processing considerably - may crash sketchup - use sparingly. turn $verbose on around desired areas
$verboseComponentDiscovery = false # trace model entity list traversal only
$verbosePartPlacement = false #trace parts placement for layout only
$verboseParameters = false # trace parameter passing to/from the GUI




