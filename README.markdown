# README for Cutlister

Cutlister is a Google SketchUp Plugin that automates the creating of cut lists for your project. This plugin also exports layouts for your sheet and part goods, allowing you to visualize exactly how much material you will need and how to cut it out, thus saving you material on your next project.

This plugin is specifically designed for cabinet makers and woodworkers, but could also apply to other industries and applications.

Cutlister takes all the selected entities in your model and creates a cut list for those parts

* **Sheet goods** -- Any sheet good (e.g. plywood, MDF, etc...)
* **Parts** (lumber parts)
* **Components** (everything else...).

The plugin exports these items in a variety of lists


## Installation

Copy the file `Cutlister.rb` file and the `Cutlister` directory into your SketchUp plugin directory:

On a **Mac** it is usually here:

    Macintosh HD/Library/Application Support/Google SketchUp X/SketchUp/

On **Windows** it should be here:

    C:\Program Files\Google\Google Sketchup X\Plugins\

.. where `X` is the version of SketchUp you are running.

Once the plugin is copied over, restart SketchUp and the plugin should be working.


## Usage

To use Cutlister, just select the items in your model you want to cut list and right-click (context click) on them and select "Cutlist Selection", or use the item in the "Plugins" menu, or the Toolbar item.

In order to get Cutlister to work right in your models, you may need to make some changes to your workflow. Below is the general work flow for getting Cutlister to work as expected.

Layers are used to group similar components to make it easier to isolate them and make changes. It has nothing to do with the cut listing of parts.

Group each individual part to isolate it's geometry. Give the part a name (e.g. "Wall End", "Door", "Back", etc...) which will be used within Cutlister.

Group collections of parts into sub-assemblies (e.g. Cabinet numbers, like "101 1", "204 7", etc...) which will be used as the cabinet number in the cut listing program. You can use any naming convention that you like, you are not limited to numbering your cabinets in any particular way.

Give the individual parts a material fill (e.g. "PF-MAPLE", "MDF", etc...) which will be used as the material in Cutlister. Do not apply a material to a group of components because the properties will not work in Cutlister (e.g. don't give the cabinet a material but give the parts that make up the cabinet a material).

There are three main items that are exported by Cutlister:

* **SHEET** -- Anything cut out of sheet stock.
* **PART** -- Part is anything cut out of lumber.
* **COMPONENT** -- Anything else. (e.g. Hardware, accessories, appliances, etc...)

Within Cutlister you have various output options including HTML, CSV and CutList Plus. 


## Extending Cutlister

Cutlister is designed to be extensible. This means that you can create new output formats and cut list layouts based on your needs. If you wanted to export an XML file, for example, you could create a sub-class of the `Renderer`class (in `renderer.rb`)  to construct your XML file and then create a sub-class of the `OutputDriver` class (in `display.rb`) to format the cut list output to work with XML.


## Credits

Cutlister was born out of [CutList](http://steveracz.com/joomla/content/view/45/1/) project by: 

* [Steve Racz](http://steveracz.com/)
* Dave Richards

The differences of Cutlister from CutList is as follows:

* **More Easily Extendable** -- Adding new output formats or cut list types are much more streamlined, with automatic sub-class "sniffing", which means that if you sub-class `OutputFormat` or `Cutlist` the plug-in automatically adds the new sub-class to the list of formats and list types. To add a new output format or cut list all you need to do is create a sub-class of the parent class and define how it should work, everything else is taken care of.
* **Improved User Interface** -- The design for the plugin was cleaned up and improved to be easier to use and more attractive as well as more easily modifiable. The interface has automatic notification messages built in, rather than the somewhat annoying pop-up messages.
* **Version Controlled and Open Source** -- The plugin is [hosted on Github](https://github.com/danawoodman/Google-Sketchup-Cutlister-Plugin) and is released under a MIT license (see the `LICENSE` file for more information on the license). This means you can fork it, modify the code and use it in any manner you please.
* **Cleaned Up and More Commented Code** -- Where possible I provided comments on the code as to what is going on so modification and understanding of the code is improved. I will also make my best attempt at keeping a good tutorial and reference page maintained so extending this plug-in will be as straight forward as possible.
