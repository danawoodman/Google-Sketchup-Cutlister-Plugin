# README for [Cutlister][]

[Cutlister][] is a Google SketchUp Plugin that automates the creating of cut lists for your project. This plugin also exports layouts for your sheet and part goods, allowing you to visualize exactly how much material you will need and how to cut it out, thus saving you material on your next project.

This plugin is specifically designed for cabinet makers and woodworkers, but could also apply to other industries and applications.

[Cutlister][] takes all the selected entities in your model and creates a cut list for those parts

* **Sheet goods** -- Any sheet good (e.g. plywood, MDF, etc...)
* **Solid Stock** -- Anything cut out of lumber.
* **Hardware** -- Anything else (e.g. Accessories, appliances, etc...)

The plugin exports these items in a variety of lists types and formats.

You can choose from outputting an HTML page, a CSV file (for importing into programs like Microsoft Office and Apple iWork Numbers). 

This plugin was designed to be extendable, allowing you to add your own output formats, cut lists and renderers. This means you could generate custom cut lists for your own particular needs without changing anything in the current code (more on this below).


## Installation

Copy the file `[Cutlister][].rb` file and the `[Cutlister][]` directory into your SketchUp plugin directory:

On a **Mac** it is usually here:

    Macintosh HD/Library/Application Support/Google SketchUp X/SketchUp/

On **Windows** it should be here:

    C:\Program Files\Google\Google Sketchup X\Plugins\

.. where `X` is the version of SketchUp you are running.

Once the plugin is copied over, restart SketchUp and the plugin should be working.

You will see a right-click context menu item called "Cutlist selection" as well as a menu entry under "Plugins" named "Cutlist model".


## Usage

To use [Cutlister][], just select the items in your model you want to cut list and right-click (context click) on them and select "Cutlist Selection", or use the item in the "Plugins" menu, or the Toolbar item.

In order to get [Cutlister][] to work right in your models, you may need to make some changes to your workflow. Below is the general work flow for getting [Cutlister][] to work as expected:

Layers are used to group similar parts to make it easier to isolate them and make changes (e.g. "Doors", "Shelfs", "Counters", etc...). *It has nothing to do with the cut listing of parts*.

Group each individual part to isolate it's geometry. Give the part a name (e.g. "Wall End", "Door", "Back", etc...) which will be used within [Cutlister][] as the *Part Name* in [Cutlister][].

Group collections of parts into sub-assemblies (e.g. Cabinet numbers, like "101 1", "204 7", "Kitchen Vanity", etc...) which will be used as the cabinet number in the cut listing program. *You can use any naming convention that you like*, you are not limited to numbering your cabinets in any particular way. This will be used as the *Cabinet Name* in [Cutlister][].

Give the individual parts a material fill (e.g. "PF-MAPLE", "MDF", "Poplar". etc...) which will be *used as the material in [Cutlister][]*. Do not apply a material to a group of components because the properties will not work in [Cutlister][] (e.g. don't give the cabinet a material but give the parts that make up the cabinet a material). *Material numbers can be have letters, numbers, spaces, dashes (-), underscores (_) and be upper or lowercase*.

Once your models is setup, you can begin to cut list.

Once you have the [Cutlister][] popup menu open, set your options


## Extending [Cutlister][]

[Cutlister][] is designed to be extensible. This means that you can create new output formats and cut list layouts based on your needs. 

If you wanted to export an XML file, for example, you could create a sub-class of the `Renderer`class (which is found in `renderers.rb`)  to construct your XML file and then create a sub-class of the `Cutlist` class (in `cutlist.rb`) to format the cut list output to work with XML.

Once you sub-class `Renderer` or `Cutlist`, your custom renderer/cutlist will show up in the popup menu

See the file `extensions` folder for an example of how to do this.


## Credits

[Cutlister][] was born out of [CutList][] project by: 

* [Steve Racz](http://steveracz.com/)
* Dave Richards

It was completely re-written from the ground up and uses only a few parts of the original code. The main differences of [Cutlister][] from CutList are as follows:

* **More Easily Extendable** -- Adding new output formats or cut list types are much more streamlined, with automatic sub-class "sniffing", which means that if you sub-class `Renderer` or `Cutlist` the plug-in automatically adds the new sub-class to the list of formats and list types. To add a new output format or cut list all you need to do is create a sub-class of the parent class and define how it should work, everything else is taken care of.
* **Improved User Interface** -- The design for the plugin was cleaned up and improved to be easier to use and more attractive as well as more easily modifiable. The interface has automatic notification messages built in, rather than the somewhat annoying pop-up messages.
* **Version Controlled and Open Source** -- The plugin is [hosted on Github](https://github.com/danawoodman/Google-Sketchup-[Cutlister][]-Plugin) and is released under a MIT license (see the `LICENSE` file for more information on the license). This means you can fork it, modify the code and use it in any manner you please.
* **Lots of Code Comments** -- Where possible I provided comments on the code as to what is going on so modification and understanding of the code is improved. I will also make my best attempt at keeping a good tutorial and reference page maintained so extending this plug-in will be as straight forward as possible.


## Notes & Caveats

One major note is that **[Cutlister][] does not do "layouts"** currently. The original [CutList][] has support for something called "layout" which allows you to output your cut list as a printable panel layout that you can use to visualize how your parts will fit on a sheet of plywood or other material.

Since [Cutlister][] was completely re-written, it must be build from the ground up, and the layout feature has not yet been integrated.

I am planning on implementing the layout features as soon as the cut listing parts are stable. If you want to contribute, please visit


## Contributing, Feedback & Bug Reports

If you want to contribute to this project, please fork [Cutlister][] at the [Github repository][Cutlister].

If you have any feedback or comments, feel free to send me an email at <dana@danawoodman.com>.

If you find bugs or have a feature request, please add them at the [GitHub repository][githubrepo]

## License

[Cutlister][] is licensed under an MIT license (see the `LICENSE` file for more information).


[Cutlister]: https://github.com/danawoodman/Google-Sketchup-Cutlister-Plugin "Visit the Cutlister GitHub page"
[CutList]: http://steveracz.com/joomla/content/view/45/1/ "CutList by Steve Racz"
[githubrepo]: https://github.com/danawoodman/Google-Sketchup-[Cutlister][]-Plugin/issues "Add any bugs or feature request to the Issues page"