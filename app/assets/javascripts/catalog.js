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
      var dom = getTableData(table, 'serial') ? 'frtip' : 'rtip';
      table = initTable($(table.table().node()),
          $(this).data('url'), "data", "items", dom);

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
          } else if (availability.print_available) { 
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
}

var tableOpts = {
    "locations": {
        "columns": [
            {   "title": "Location" },
            {   "title": "Availability" },
            {   "title": "Call Number" },
            {   "title": "" }
        ]
    },
    "online": {
        "columns": [
            {   "title": "Type" },        
            {   "title": "Description" },
            {   "title": "Availability" },
            {   "title": "" }
        ], 
        "order": [[0, "desc"], [1, "asc"]]
    },       
    "items": {
        "columns": [
            {   "title": "Barcode/Description",
                "orderable": true
            },
            {   "title": "Type", 
                "orderable": false
            },
            {   "title": "Policy",
                "orderable": false
            },
            {   "title": "",
                "orderable": false
            }        
        ],
        "order": [[0, "desc"]],
        "serverSide": true
    }
};

function initLocationsTable(elem) {
    var data = availabilityData[elem.data("id")];
    table.data('serial', data.serial)
    table = initTable(elem, null, data.print, "locations");
    $("div.toolbar").addClass('pull-left');
    if (!getTableData(table, 'serial')) {
      $("div.toolbar").append(`<strong>Requests: <span class="badge">${data.requests}</span></strong>&nbsp;`);
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
            requestDropdown.append( '<li><a target="request" href="' + val.link + '">' + val.desc + '</li>' );
        });
      });
    }
    return table;
}

function initTable(elem, url, dataSrc, tabopts, dom=null) {
  if ($.fn.DataTable.isDataTable(elem)) elem.DataTable().destroy();
  var opts = {
    "processing": true,
    "pageLength": 5,
    "retrieve": true,
    "language": {
      "processing": '<i class="fa fa-spinner fa-spin"></i> Loading...',
      "paginate": {
        "first": '<<',
        "next": '>',
        "last": '>>',
        "previous": '<'
      }
    },
    "dom": '<"toolbar">' + (dom || 'rtip')
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

