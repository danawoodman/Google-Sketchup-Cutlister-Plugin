
// jQuery save form data function.
(function($) {

    $.fn.save_form_data = function(options) {
        
        // Compile default options and user specified options.
        var opts = $.extend({}, $.fn.save_form_data.defaults, options);

        return this.each(function() {
            
            var $this = $(this);

            // Build element specific options.
            $this.o = $.meta ? $.extend({}, opts, $this.data()) : opts;
            
            // Check if it is a form.
            if ($this.is('form')) {
                
                // Loop through all the fields in the form.
                $this.find('input,select,textarea').each(function() {
                    if ($(this).is('input:checkbox, input:radio')) {
                        $.cookie($(this).attr('name'), $(this).attr('checked'), { 'expires': $this.o.expires } );
                    } else if ($(this).is('input:text, input:password, select, textarea')) {
                        $.cookie($(this).attr('name'), $(this).val(), { 'expires': $this.o.expires } );
                    };
                });
            };
            
        });
    };

    $.fn.save_form_data.defaults = {
        expires: 3650 // When the cookie should expire in days. Default is 10 years.
    };

})(jQuery);

// jQuery load form data function.
(function($) {

    $.fn.load_form_data = function(options) {
        
        // Compile default options and user specified options.
        var opts = $.extend({}, $.fn.load_form_data.defaults, options);

        return this.each(function() {
            
            var $this = $(this);

            // Build element specific options.
            $this.o = $.meta ? $.extend({}, opts, $this.data()) : opts;
            
            // Check if it is a form.
            if ($this.is('form')) {
                
                // // Loop through all the fields in the form.
                $this.find('input,select,textarea').each(function() {
                    
                    if ($.cookie($(this).attr('name'))) {
                        
                        // If the field is a checkbox, mark it checked or unchecked.
                        if ($(this).is('input:checkbox,input:radio')) {
                            $(this).attr('checked', $.cookie($(this).attr('name')) == 'true' ? 'checked' : '');
                        } else {
                            $(this).val($.cookie($(this).attr('name')));
                        };
                        
                    };
                });
            };
        });
    };

    $.fn.load_form_data.defaults = {
        
    };

})(jQuery);

// jQuery populate <select> fields function.
(function($) {

    $.fn.populate_select = function(options) {
        
        // alert('Populating ' + this.selector + ' select options...');
        
        // Compile default options and user specified options.
        var opts = $.extend({}, $.fn.populate_select.defaults, options);

        return this.each(function() {
            
            var $this = $(this);

            // Build element specific options.
            $this.o = $.meta ? $.extend({}, opts, $this.data()) : opts;

            if ($this.o.items) {

                $.each($this.o.items, function(index, element) {

                    // console.log('appending ' + opts.items[index][0] + ' and ' + opts.items[index][1] + ' to ' + opts.selector);
                    
                    $($this).append($("<option></option>").attr("value", $this.o.items[index][0]).text($this.o.items[index][1]));


                });

            } else {
                console.log('No items to populate select with...');
            };
        });
    };

    $.fn.populate_select.defaults = {
        items: [] // An array of items to populate the select with. Should be an array of arrays with each item array looking like: ['value', 'Option Name']
    };

})(jQuery);

// jQuery: DOM load...
$(function() {
    
    // Run the load_settings function to load cookies.
    $('form').load_form_data();
    
    // jQuery tabs.
    $('#tabs').tabs();
    
    // Bind the handle_close action to the close button.
    $('#id_close').bind('click', function() {

        window.location = 'skp:handle_close@x';

    });
    
    // Bind the save settings button to the save_settings function.
    $('#id_save_settings').bind('click', function() {

        // save_settings(form);
        $('#cutlist-form').save_form_data();
        // $('#notice-area').html('<p>Your settings have been saved!</p>');
        $('#notice-area').fadeIn().delay(2000).fadeOut('slow'); //.html('')

    });
    
    // Send data to SketchUp plugin after form submit.
    $('#cutlist-form').pass_to_sketchup({
        method: 'handle_run'
    });
    
});
