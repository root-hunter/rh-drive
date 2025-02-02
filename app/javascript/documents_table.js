document.addEventListener("DOMContentLoaded", function () {
    DataTable.pipeline = function (opts) {
        // Configuration options
        var conf = Object.assign(
            {
                pages: 5, // number of pages to cache
                url: '', // script url
                data: null, // function or object with parameters to send to the server
                // matching how `ajax.data` works in DataTables
                method: 'POST' // Ajax HTTP method
            },
            opts
        );

        // Private variables for storing the cache
        var cacheLower = -1;
        var cacheUpper = null;
        var cacheLastRequest = null;
        var cacheLastJson = null;

        return async function (request, drawCallback, settings) {
            var ajax = false;
            var requestStart = request.start;
            var drawStart = request.start;
            var requestLength = request.length;
            var requestEnd = requestStart + requestLength;

            if (settings.clearCache) {
                // API requested that the cache be cleared
                ajax = true;
                settings.clearCache = false;
            }
            else if (
                cacheLower < 0 ||
                requestStart < cacheLower ||
                requestEnd > cacheUpper
            ) {
                // outside cached data - need to make a request
                ajax = true;
            }
            else if (
                JSON.stringify(request.order) !==
                JSON.stringify(cacheLastRequest.order) ||
                JSON.stringify(request.columns) !==
                JSON.stringify(cacheLastRequest.columns) ||
                JSON.stringify(request.search) !==
                JSON.stringify(cacheLastRequest.search)
            ) {
                // properties changed (ordering, columns, searching)
                ajax = true;
            }

            // Store the request for checking next time around
            cacheLastRequest = JSON.parse(JSON.stringify(request));

            if (ajax) {
                // Need data from the server
                if (requestStart < cacheLower) {
                    requestStart = requestStart - requestLength * (conf.pages - 1);

                    if (requestStart < 0) {
                        requestStart = 0;
                    }
                }

                cacheLower = requestStart;
                cacheUpper = requestStart + requestLength * conf.pages;

                request.start = requestStart;
                request.length = requestLength * conf.pages;

                // Provide the same `data` options as DataTables.
                if (typeof conf.data === 'function') {
                    // As a function it is executed with the data object as an arg
                    // for manipulation. If an object is returned, it is used as the
                    // data object to submit
                    var d = conf.data(request);
                    if (d) {
                        Object.assign(request, d);
                    }
                }
                else if (conf.data) {
                    // As an object, the data given extends the default
                    Object.assign(request, conf.data);
                }
                const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
                // Use `fetch` to make Ajax request
                let response = await fetch(
                    `${conf.url}.json`,
                    {
                        method: conf.method,
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-Token': csrfToken  // Include the CSRF token in the headers
                        },
                        body: JSON.stringify(request)
                    }
                );
                console.log(request)

                let result = await response.json();

                console.log(documentsTableSettings)

                cacheLastJson = JSON.parse(JSON.stringify(result));

                if (cacheLower != drawStart) {
                    result.data.splice(0, drawStart - cacheLower);
                }
                if (requestLength >= -1) {
                    result.data.splice(requestLength, result.data.length);
                }

                drawCallback(result);
            }
            else {
                json = JSON.parse(JSON.stringify(cacheLastJson));
                json.draw = request.draw; // Update the echo for each response
                json.data.splice(0, requestStart - cacheLower);
                json.data.splice(requestLength, json.data.length);

                drawCallback(json);
            }
        };
    };

    // Register an API method that will empty the pipelined data, forcing an Ajax
    // fetch on the next draw (i.e. `table.clearPipeline().draw()`)
    DataTable.Api.register('clearPipeline()', function () {
        return this.iterator('table', function (settings) {
            settings.clearCache = true;
        });
    });

    const documentsTable = new DataTable('#table-documents', {
        lengthMenu: [[10, 25, 50, -1], [10, 25, 50, "All"]],
        ajax: DataTable.pipeline({
            url: '/documents/query',
            pages: 10
        }),
        layout: {
            top1Start: {
                buttons: [
                    {
                        extend: 'colvis',
                        columns: ':not(.notexport)'
                    },
                    {
                        extend: 'copyHtml5',
                        className: 'btn btn-secondary',
                        exportOptions: {
                            columns: ':not(.notexport)'
                        },
                        split: [
                            {
                                extend: 'pdfHtml5',
                                exportOptions: {
                                    columns: ':not(.notexport)'
                                }       
                            },
                            {
                                extend: 'excelHtml5',
                                exportOptions: {
                                    columns: ':not(.notexport)'
                                }       
                            },
                            {
                                extend: 'csvHtml5',
                                exportOptions: {
                                    columns: ':not(.notexport)'
                                }       
                            }
                        ]
                    }
                ]
            },
            top1End: {
                buttons: [
                    {
                        text: 'Clear cache',
                        action: function (e, dt, node, config) {
                            documentsTable.clearPipeline().draw()
                        }
                    }
                ]
            }
        },
        columns: [
            {
                data: null,
                orderable: false,
                searchable: false,
                render: DataTable.render.select()
            },
            {
                visible: false,
                name: "id",
                render: formatTextColumn("id")
            },
            {
                visible: false,
                name: "folder_id",
                render: formatTextColumn("folder_id")
            },
            {
                visible: false,
                name: "folder_path",
                render: formatTextColumn("folder_path")
            },
            {
                name: "filename",
                render: formatLinkColumn("/documents", "id", "filename")
            },
            {
                name: "type",
                render: formatTextColumn("type")
            },
            {
                name: "size",
                render: formatByteColumn("size")
            },
            {
                name: "created_at",
                visible: false,
                render: formatDateColumn("created_at"),
            },
            {
                name: "updated_at",
                render: formatDateColumn("updated_at"),
            },
        ],
        processing: true,
        serverSide: true,
        select: true,
        order: [[3, "asc"]],
        rowGroup: {
            dataSrc: "folder_path"
        }
    });

    const documentsTableSettings = documentsTable.settings();
});