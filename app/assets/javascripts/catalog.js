var table;
var availabilityData;

function checkAvailability() {
    $(".availability").click(function(e) {
        var dtDiv = $(this).closest("div").find(".fulfillment-dt").toggle();

        // Close other tables
        $("div.fulfillment-dt").not(dtDiv).hide()
            .parent().find("i").removeClass("fa-chevron-down").addClass("fa-chevron-right");

        $(this).children('.fa').toggleClass("fa-chevron-right fa-chevron-down");
        table = $(`table[data-id="${$(this).attr('id').match(/\d*$/)}"]`);
        if ($(this).attr('id').startsWith('online')) {
            table = initTable(table, null, availabilityData[table.data("id")]["online"], "online");
        } else {
            table = initLocationsTable(table);
        }
    });

    $("tbody").on('click', 'button.items', function() {
        var data = table.row($(this).parents('tr')).data();
        table = initTable($(table.table().node()),
            data['items_url'], "item", "items");

        $("div.toolbar").html(`<button type="button" class="btn btn-default pull-left">
            <span class="glyphicon glyphicon-chevron-left"></span> Back to locations</button>`);
        $("div.toolbar button").click(function(e) {
            var id = getTableData(table, 'id');
            table = initLocationsTable($('table[data-id="' + id + '"]'));
        });
    });

    // Check availability for each search result
    $('#checking_availability').show();
    var mms_ids = $(".documents-list .document").map(function() { 
        return $(this).data('id')
    }).get().join(",");
    $.get("/almaws/bibs/availability?mms_ids=" + mms_ids, 
        function(data, status) {
            availabilityData = data;
            for (var mms_id in data) {
                var availability = data[mms_id];
                $('#physical-' + mms_id).toggleClass(function() {
                    if (!availability.print.length>0) { 
                        return "disabled";
                    } else if (availability.print.find(function(e) { return e.e == 'available'} )) { 
                        return "btn-default btn-success";
                    } else {
                        return "btn-default btn-warning";
                    }
                });
                $('#online-' + mms_id).toggleClass(function() {
                    if (!availability.online.length>0) { 
                        return "disabled";
                    } else {
                        return "btn-default btn-success";
                    }
                });
            }
            $('#checking_availability').hide();
    });

    var tableOpts = {
        "locations": {
            "columns": [
                {   "title": "Location",
                    "render": function( data, type, row, meta ) {
                        return `${row.c} - ${row.q}`; 
                    }
                },
                {   "title": "Availability",
                    "render": function( data, type, row, meta ) {
                        var c = row.f-row.g > 0 ? 'green' : 'grey'
                        var resp = `<span class="glyphicon glyphicon-dot glyphicon-${c}"></span> `;
                        return resp + (row.t || row.h || 
                            `Copies: ${row.f}, Available: ${row.f-row.g}`); 
                    }
                },
                {   "title": "Call Number",
                    "data": "d" ,
                    "defaultContent": ""
                },
                {
                    "title": "",
                    "defaultContent": "<button class='btn btn-default btn-sm items'>Details</button>"
                }
            ],
            "dom": '<"toolbar">rtip'
        },
        "online": {
            "columns": [
                {
                    "title": "Type",
                    "render": function( data, type, row, meta ) {
                        return row.digital ? 'Digital' : 'Electronic'; 
                    }
                },        
                {   "title": "Description",
                    "render": function( data, type, row, meta ) {
                        return row.digital ? row.e : row.m; 
                    }
                },
                {   "title": "Availability",
                    "render": function( data, type, row, meta ) {
                        var resp = `<span class="glyphicon glyphicon-dot glyphicon-green"></span> `;
                        return resp + (row.s || 'Available');
                    }
                },
                {   "title": "",
                    "render": function( data, type, row, meta ) {
                        return `<a class="btn btn-default btn-sm" href="${row.link}" target="_new">View online</a>`;
                    }
                }
            ], 
            "order": [[0, "desc"], [1, "asc"]],
            "dom": '<"toolbar">rtip'
        },       
        "items": {
            "columns": [
                {   "title": "Barcode/Description",
                    "render": function( data, type, row, meta ) {
                        if (getTableData(table,'serial')) 
                            return row.item_data.description;
                        else return row.item_data.barcode;
                    }
                },
                {   "title": "Type",
                    "data": "item_data.physical_material_type.desc"
                },
                {   "title": "Policy",
                    "data": "item_data.due_date_policy",
                    "defaultContent": ""
                },
                {
                    "title": "",
                    "render": function( data, type, row, meta ) {
                        if (getTableData(table,'serial')) 
                            return `<a class="btn btn-default btn-sm" href="/card/requests/new?mms_id=${row.bib_data.mms_id}&holding_id=${row.holding_data.holding_id}&item_id=${row.item_data.pid}">Request</a>`;
                    },
                    "defaultContent": ""
                }        
            ],
            "order": [[0, "desc"]],
            "dom": '<"toolbar">frtip'
        }
    };

    function initLocationsTable(elem) {
        var data = availabilityData[elem.data("id")];
        table.data('serial', data.serial)
        table = initTable(elem, null, data.print, "locations");
        $("div.toolbar").addClass('pull-left');
        if (!getTableData(table, 'serial')) {
            $("div.toolbar").append('<strong>Requests: <span class="badge"></span></strong>&nbsp;');
            $.getJSON ( getTableData(table, 'url') + '/requests', function( data ) {
                $("div.toolbar").find("span.badge").html(data.total_record_count);
            });
            var requestDropdown = $("div.toolbar").append(`
                <div class="btn-group">
                  <button type="button" class="btn btn-default btn-sm dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                    <i class="fa fa-spinner fa-spin"></i> New <span class="caret"></span>
                  </button>
                  <ul class="dropdown-menu">
                  </ul>
                </div>`);
            requestDropdown = $(requestDropdown).find('ul');
            $.getJSON( getTableData(table, 'url') + '/request-options', function( data ) {
                $(requestDropdown).siblings('button').find('i').removeClass('fa-spinner fa-spin')
                $.each( data, function( key, val ) {
                    requestDropdown.append( '<li><a href="' + val.link + '">' + val.type.desc + ' Request</li>' );
                });
            });
        }
        return table;
    }

    function initTable(elem, url, dataSrc, tabopts) {
        if ($.fn.DataTable.isDataTable(elem)) elem.DataTable().destroy();
        var opts = {
            "processing": true,
            "pageLength": 5,
            "retrieve": true,
            "language": {
                "loadingRecords": '<i class="fa fa-spinner fa-spin"></i> Loading...',
                "paginate": {
                    "first": '<<',
                    "next": '>',
                    "last": '>>',
                    "previous": '<'
                }
            }
        }
        if (url) opts["ajax"] = { "url": url, "dataSrc": dataSrc }
        else opts["data"] =  dataSrc;
        return elem.DataTable($.extend(opts, tableOpts[tabopts]));
    }

    function getTableData(table, data) {
        if (table.table) {
            return $(table.table().node()).data(data);    
        } else {
            return table.data(data);
        }
        
    }
}
