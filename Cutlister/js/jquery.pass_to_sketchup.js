(function($) {
    
    // Pass data to SketchUp
    $.fn.pass_to_sketchup = function(options) {
        
        // Compile default options and user specified options.
        var opts = $.extend({}, $.fn.pass_to_sketchup.defaults, options);
        
        return $(this).each(function() {
            
            var obj = $(this);
            
            // Build element specific options.
            obj.o = $.meta ? $.extend({}, opts, $this.data()) : opts;
            
            var params;
            
            // A Ruby method name was passed, return continue on as exepcted...
            if (obj.o.method) {
                
                // If the jQuery object the plugin was called from is a form, then 
                // wait for a submission event.
                if (obj.is('form')) {

                    obj.submit(function() {

                        // If the plugin was passed a param string, use that to pass to 
                        // the Ruby method.
                        if (obj.o.params) {

                            params = obj.o.params;

                        // If there was no string passed to the plugin, use the 
                        // serialized form data. Will return something like: 
                        // "foo=1&bar=true&baz=Something"
                        } else {

                            params = obj.serialize();

                        };
                        
                        if (obj.o.debug) { alert('Passing params: "' + params + '" to Ruby method: "' + obj.o.method + '"') };

                        // Pass the params to the SketchUp method.
                        window.location = 'skp:' + obj.o.method + '@' + params;

                        return false;

                    });

                // The plugin was called somewhere other than a form, just return 
                // the params as is.
                } else {

                    if (obj.o.params) {

                        window.location = 'skp:' + obj.o.method + '@' + obj.o.params;

                        return false;

                    } else {
                        
                        if (obj.o.debug) { alert('You must pass the plugin a string of parameters for it to work!!!') };
                        
                    };

                };
            
            // A method was not defined in the plugin options, alert the user!
            } else {
                
                if (obj.o.debug) { alert('You must declare a method option for this plugin to work!!!') };
                
            };
            
        });
    };
    
    $.fn.pass_to_sketchup.defaults = {
        debug: false, // Boolean. Optional. Turn on/off debug messages. Default is false.
        method: '', // String. Required. The Ruby method to pass data to. Default is ''.
        params: '' // String. Optional. The params to pass to SketchUp. Leave blank to pass form data. Default is ''.
    };

})(jQuery);
