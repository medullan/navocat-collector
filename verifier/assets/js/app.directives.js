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
    '$timeout',
    function($log, $timeout) {

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

            var hasSrchVal = angular.isString(scope.searchval) && scope.searchval.length > 0;
            var level = 1;
            level = (hasSrchVal) ? 'all' : level;
            var node = renderjson
                //.set_show_by_default(true)
                .set_show_to_level(level)
                //.set_sort_objects(true)
                .set_icons('+', '-')
                .set_max_string_length(50)(input);
            element.html(node);

            function filter(){
                var contains = _.contains($(this).text().toLowerCase(), scope.searchval.toLowerCase());
                if(contains){
                    $(this).addClass('match srch-match srch-match-value');
                    $(this).prevAll('.key:first').addClass('match srch-match srch-match-key');
                    $(this).parentsUntil("pre.renderjson").addClass('match srch-match srch-match-path');
                }
                return contains;
            }

            if(hasSrchVal){
                element.find("span").filter(filter).toArray();
            }
        }
        var directive = {
            restrict: 'EA',
            scope: {
                log: '=log',
                omit: '=omit',
                searchval: '=search'
            },
            link: link
        };
        return directive;
    }]);
