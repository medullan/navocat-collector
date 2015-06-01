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


angular.module('core').service('VerifyMemberId', [
    '$q',
    '$http',
    function($q, $http) {
        var self= this;
        self.verify = function(val){
            var deferred = $q.defer();
            $http.post('/meda/verification/memberid', {member_id:val}).
                success(function(data, status, headers, config) {
                    // this callback will be called asynchronously
                    // when the response is available
                    deferred.resolve(data);
                }).
                error(function(data, status, headers, config) {
                    // called asynchronously if an error occurs
                    // or server returns response with an error status.
                    deferred.reject(data)
                });
            return deferred.promise
        };

        var customFilter = {
            'end_point_type':function(item, crit, val){
                return _.contains(item.http[crit].toLowerCase(), val.toLowerCase());
            },
            'member_id': function(item, crit, val){
                var val1 =  (item['profile_id']) ? item['profile_id'].toLowerCase() : null;
                var val2 =  (val) ? val.toLowerCase() : null;
                return _.contains(val1 , val2);
            }
        };
        var extraData = {
            'member_id': function( crit, val){
                var deferred = $q.defer();
                self.verify(val).then(function(data){
                    deferred.resolve(data);
                });
                return deferred.promise;
            }
        };
        function query(json, criteria, value) {
            var custom = ['end_point_type', 'member_id'];
            return Enumerable.From(json)
                .Where(function (item) {
                    var result = false;
                    if (_.contains(custom, criteria)) {
                        result = customFilter[criteria](item, criteria, value);
                    } else {
                        result = _.contains(item[criteria].toLowerCase(), value.toLowerCase());
                    }
                    return result;
                })
                .ToArray();
        }

        self.filter= function(json, criteria, value, isXhr){
            var deferred = $q.defer();
            var data = ['member_id'];
            if(_.contains(data, criteria)){
                extraData[criteria](criteria, value).then(function(data){
                    var result = query(json, criteria, data.hash);
                    deferred.resolve(result) ;
                });
            }else{
                var result = query(json, criteria, value);
                deferred.resolve(result) ;
            }

            return deferred.promise;
        };
    }
]);

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