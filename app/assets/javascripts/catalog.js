var table;

function checkAvailability() {
    $(".availability").click(function(e) {
        $(this).children('.fa').toggleClass("fa-chevron-right fa-chevron-down");
        var online = $(this).attr('id').startsWith('online');
        $(this).closest("div").find(".fulfillment-dt").toggle();
        if ( ! $.fn.DataTable.isDataTable( table )) {
            table = $(this).closest("div").find("table[role='datatable']");
            if (online) {
                table = initTable(table, table.data('url') + '/availability', 
                    "online", "online", '<"toolbar">rtip');
            } else {
                var icon = $(this).find('i');
                icon.addClass('fa-spinner fa-spin');
                $.getJSON( table.data('url'), function(data) {
                    icon.removeClass('fa-spinner fa-spin');
                    table.data('serial', data.serial);
                    table = initLocationsTable(table, table.data('url'));
                });
            }
        }
    });

    $("tbody").on('click', 'button.items', function() {
        var data = table.row($(this).parents('tr')).data();
        var url = getTableData(table, 'url');
        table.destroy();
        table = initTable($(table.table().node()),
            `${url}/holdings/${data['8']}/items`,
            "item", "items", '<"toolbar">frtip');

        $("div.toolbar").html(`<button type="button" class="btn btn-default pull-left">
            <span class="glyphicon glyphicon-chevron-left"></span> Back to locations</button>`);
        $("div.toolbar button").click(function(e) {
            var id = getTableData(table, 'id');
            var url = getTableData(table, 'url');
            table.destroy();
            table = initLocationsTable($('table[data-id="' + id + '"]'), url);
        });
    });

    // Check availability for each search result
    $('#checking_availability').show();
    var mms_ids = $(".documents-list .document").map(function() { 
        return $(this).data('id')
    }).get().join(",");
    $.get("/almaws/bibs/availability?mms_ids=" + mms_ids, 
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
                        if (getTableData(table,'serial')) 
                            return resp + ` ${row.t || row.h}`; 
                        else
                            return resp + ` Copies: ${row.f}, Available: ${row.f-row.g}`; 
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
                        return resp + (row.digital ? 'Available' : row.s);
                    }
                },
                {   "title": "",
                    "render": function( data, type, row, meta ) {
                        return `<a class="btn btn-default btn-sm" href="${row.link}" target="_new">View online</a>`;
                    }
                }
            ], 
            "order": [[0, "desc"], [1, "asc"]]
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
            "order": [[0, "desc"]]
        }
    }

    function initLocationsTable(elem, url) {
        table = initTable(elem, url + '/availability', 
            "print", "locations", '<"toolbar">rtip');
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
                    requestDropdown.append( '<li><a href="' + val.url + '">' + val.desc + '</li>' );
                });
            });
        }
        return table;
    }

    function initTable(elem, url, dataSrc, tabopts, dom="") {
        var opts = {
            "processing": true,
            "pageLength": 5,
            "ajax": {
                "url": url,
                "dataSrc": dataSrc
            },
            "dom": dom,
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
        return elem.DataTable($.extend(opts, tableOpts[tabopts]));
    }

    function getTableData(table, data) {
        return $(table.table().node()).data(data);
    }

    function setTableData(table, data, value) {
        $(table.table().node()).data(data, value);
    }
}
