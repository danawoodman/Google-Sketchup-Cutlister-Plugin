#-----------------------------------------------------------------------------
#
# Copyright 2010 Dana Woodman, Phoenix Woodworks. All Rights Reserved.
#
# Permission to use, copy, modify, and distribute this software for
# any purpose and without fee is hereby granted, provided the above
# copyright notice appear in all copies.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#-----------------------------------------------------------------------------
#
# Name        : Cutlister
# Based On    : Cutlister by Steve Racz & Dave Richards
# Type        : Tool
# Author      : Dana Woodman
# Email       : <dana@danawoodman.com>
# Website     : https://github.com/danawoodman/Google-Sketchup-Cutlister-Plugin
# Blog        : 
#
# Maintenance : Please report all bugs or strange behavior to <dana@danawoodman.com>
#
# Version     : 1.0
#
# Menu Items  : Plugins -> Cutlist Model
#
# Toolbar     : Cutlist Material - Includes one large and one small icon.
#
# Context-Menu: Cutlist Selection
#
# Description : Automates the creating of cut lists for your woodworking project. 
#             : A cut list is a table of parts used to make up a piece of 
#             : cabinetry or furniture (such as a door, wall end, back or finished end).
#
# To Install  : Place the Cutlister.rb Ruby script and the 
#             : `Cutlister` directory in the SketchUp Plugins folder.
#-----------------------------------------------------------------------------

require 'sketchup.rb'
require 'extensions.rb'

# Toggle whether debugging is on or off ("true" means on, "false" means off).
CUTLISTER_VERSION = '1.0'
CUTLISTER_DEBUG = false
CUTLISTER_BASE_PATH = File.dirname(__FILE__)

# Register plugin as an extension.
cutlister_extension = SketchupExtension.new "Cutlister", File.join(CUTLISTER_BASE_PATH, "Cutlister/main.rb")
cutlister_extension.version = CUTLISTER_VERSION
cutlister_extension.creator = 'Dana Woodman'
cutlister_extension.copyright = '2010-2011'
cutlister_extension.description = "Automates the creating of cut lists for your woodworking project. A cut list is a table of parts used to make up a piece of cabinetry or furniture (such as a door, wall end, back or finished end)."
Sketchup.register_extension cutlister_extension, true
