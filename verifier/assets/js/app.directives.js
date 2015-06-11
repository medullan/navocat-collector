/**
 * Created by layton on 6/3/15.
 */
angular.module('core').filter('null', function() {
    return function(input) {
        return input ? input : 'null';
    };
});

angular.module('core').filter('exists', function() {
    return function(input) {
        return input ? 'YES' : 'NO';
    };
});

angular.module('core').directive('jsonHuman', [
    '$log',
    function($log) {

        function searchText(srchTerm){
            var stringSrch = 'pre.renderjson span.string:contains("'+ srchTerm +'")';
            var numSrch = 'pre.renderjson span.number:contains("'+ srchTerm +'")';
            var keywordSrch = 'pre.renderjson span.keyword:contains("'+ srchTerm +'")';
            var boolSearch = 'pre.renderjson span.boolean:contains("'+ srchTerm +'")'

            var query = stringSrch + ', ' + numSrch + ', '+ keywordSrch + ', '+ boolSearch
            var foundin = $(query).addClass('srch-match');

        }

        function omit(obj, keys){
            if(angular.isObject(obj) && angular.isString(keys)){
                angular.forEach(keys.split(','), function(val){
                    delete obj[val]
                });
            }
            return obj;
        }
        function link(scope, element, attrs) {
            var input = omit(scope.log, scope.omit);
            //var node = syntaxHighlight(input);
            var node =renderjson
                //.set_show_by_default(true)
                .set_show_to_level(1)
                //.set_sort_objects(true)
                .set_icons('+', '-')
                .set_max_string_length(50)(input);
            element.html(node);
            if(angular.isString(scope.searchTerm) && scope.searchTerm.length > 0){
                searchText(scope.searchTerm)
            }
        }
        var directive = {
            restrict: 'EA',
            scope: {
                log: '=log',
                omit: '=omit',
                searchTerm: '=searchTerm'
            },
            link: link
        };
        return directive;
    }]);