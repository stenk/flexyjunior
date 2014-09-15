function replaceArrayContent(array, newContent) {
    var arguments = [0, array.length].concat(newContent);
    array.splice.apply(array, arguments);
}

var app = angular.module('flexyjunior', [])

    .controller('FlexyjuniorCtrl', function($scope, $http, $element) {
        $scope.tableNames = [];
        $scope.rows = [];
        $scope.table = null;

        $http.get('/api/tables').success(function(response) {
            replaceArrayContent($scope.tableNames, response.tables);
        });

        $scope.selectTable = function(tableName) {
            var specUrl = '/api/tables/' + tableName + '/spec';
            var rowsUrl = '/api/tables/' + tableName;

            $http.get(specUrl).success(function(response) {
                $scope.table = {
                    name: response.table.name,
                    fields: [],
                    schema: {}
                };

                angular.forEach(response.table.schema, function(field) {
                    $scope.table.fields.push(field.name);
                    $scope.table.schema[field.name] = field;
                });
            });

            $http.get(rowsUrl).success(function(response) {
                replaceArrayContent($scope.rows, response.rows);
            });
        };

        $scope.showCellInput = function(row, field) {
            if (field == 'id') return;
            row.inputFor = field;

            setTimeout(function() {
                var keyup = function() {
                    var escapeKeyCode = 27;
                    var enterKeyCode = 13;
                    if (event.keyCode == escapeKeyCode || event.keyCode == enterKeyCode) {
                        $(this).blur();
                    }
                };
                $($element).find('input').focus().keyup(keyup);
            });
        };

        $scope.hideCellInput = function(row, field) {
            row.inputFor = null;
        };

        $scope.fieldChanged = function(row, field) {
            row.changed = true;
            if (row.errors) {
                delete row.errors[field];
            }
        };

        $scope.saveRow = function(row) {
            var rowData = {};
            var baseUrl = '/api/tables/' + $scope.table.name;
            var url;
            var method;

            for (var key in row) {
                if ($scope.table.schema[key] !== undefined) {
                    rowData[key] = row[key];
                }
            }

            if (row.id) {
                method = 'patch';
                url = baseUrl + '/' + row.id;
            } else {
                method = 'post';
                url = baseUrl;
            }

            $http({
                url: url,
                method: method,
                params: { json: { row: rowData } }
            }).success(function(response) {
                if (response.errors) {
                    row.errors = response.errors;
                } else {
                    $.extend(row, response.row);
                    row.errors = {};
                    row.changed = false;
                }
            });
        };

        $scope.deleteRow = function(row) {
            $http({
                method: 'delete',
                url: '/api/tables/' + $scope.table.name + '/' + row.id
            });

            for (var i = 0; i < $scope.rows.length; i++) {
                if ($scope.rows[i].id == row.id) {
                    $scope.rows.splice(i, 1);
                    break;
                }
            }
        };

        $scope.addNewRow = function() {
            $scope.rows.push({changed: true});
            setTimeout(function() {
                $(window).scrollTop($(document).height());
            });
        };
    });
