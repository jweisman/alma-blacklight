function checkAvailability() {
        $(".availability").click(function(e) {
        var i = $(this).parent().siblings("iframe").first();
        i.attr('src',$(this).data('url'));
        $(this).children('.fa').toggleClass("fa-chevron-right fa-chevron-down");
        i.toggle();
    });

    // Check availability for each search result
    $('#checking_availability').show();
    var mms_ids = $(".documents-list .document").map(function() { 
        return $(this).data('id')
    }).get().join(",");
    $.get("/catalog/availability?mms_ids=" + mms_ids, 
        function(data, status) {
            for (var mms_id in data) {
                var availability = data[mms_id];
                $('#physical-' + mms_id).toggleClass(function() {
                    if (!availability.physical.exists) { 
                        return "disabled";
                    } else if (availability.physical.available) { 
                        return "btn-default btn-success";
                    } else {
                        return "btn-default btn-warning";
                    }
                });
                $('#online-' + mms_id).toggleClass(function() {
                    if (!availability.online.exists) { 
                        return "disabled";
                    } else {
                        return "btn-default btn-success";
                    }
                });
            }
            $('#checking_availability').hide();
    });
}
