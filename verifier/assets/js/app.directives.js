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
        }
        var directive = {
            restrict: 'EA',
            scope: {
                log: '=log',
                omit: '=omit'
            },
            link: link
        };
        return directive;
    }]);