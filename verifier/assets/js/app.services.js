/**
 * Created by layton on 5/28/15.
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
        function syntaxHighlight(json) {
            if(json){
                if (typeof json != 'string') {
                    json = JSON.stringify(json, undefined, 2);
                }
                json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
                return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
                    var cls = 'number';
                    if (/^"/.test(match)) {
                        if (/:$/.test(match)) {
                            cls = 'key';
                        } else {
                            cls = 'string';
                        }
                    } else if (/true|false/.test(match)) {
                        cls = 'boolean';
                    } else if (/null/.test(match)) {
                        cls = 'null';
                    }
                    return '<span class="' + cls + '">' + match + '</span>';
                });
            }
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
            var node = syntaxHighlight(input);
            element.find('#output').html(node);
        }
        var directive = {
            restrict: 'EA',
            scope: {
                log: '=log',
                omit: '=omit'
            },
            template: '<pre class="json" id="output"> </pre>',
            link: link,
            transclude:true
        };
        return directive;
}]);