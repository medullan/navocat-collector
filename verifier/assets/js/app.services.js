/**
 * Created by layton on 5/28/15.
 */



angular.module('core').factory('myHttpInterceptor', [
    'store',
    'CoreConstants',
    function(store, CoreConstants) {

        var factory = {
            // optional method
            'request': function(config) {
                // do something on success
                var token = store.get(CoreConstants.storeKeys.token);
                config.headers["Authorization"] = token;
                return config;
            }
        };
        return factory;
    }
]);

angular.module('core').service('UserService', [
    'CoreConstants',
    'store',
    '$q',
    '$http',
    '$log',
    function(CoreConstants, store, $q, $http, $log){
        var self = this;

        self.storeToken = function(token){
            store.set(CoreConstants.storeKeys.token, token);
            return token;
        };
        self.setRecentLogOut = function(bool){
            store.set(CoreConstants.storeKeys.recentLogOut, bool);
            return bool;
        };
        self.recentLogOut = function(){
            return store.get(CoreConstants.storeKeys.recentLogOut);
        };
        self.getToken = function(){
            var token = store.get(CoreConstants.storeKeys.token);
            return token;
        };

        self.tokenExists = function(token){
            var token = self.getToken();
            if(angular.isString(token) && token.length > 0){
                return true;
            }
            return false;
        };

        self.deleteStores = function(){
            store.remove(CoreConstants.storeKeys.token);
            store.remove(CoreConstants.storeKeys.recentLogOut);
        };

        self.verifyPrivateKey = function(key){
            var deferred = $q.defer();
            $http.post('/meda/verification/key', {key: key})
                .success(function(data, status, headers, config) {
                    deferred.resolve(data);
                }).
                error(function(data, status, headers, config) {
                    $log.log('err: ', data);
                    deferred.reject(data);
                });

            return deferred.promise;
        };
    }

]);

angular.module('core').service('LogStoreService', [
    'CoreConstants',
    'store',
    '$q',
    '$http',
    '$log',
    'CoreService',
    function(CoreConstants, store, $q, $http, $log, CoreService){
        var self = this;
        self.getLogIds = function(logs){
            var getID = function(log){
                if(angular.isObject(log) && angular.isString(log.id)){
                    return log.id;
                }
            };
            if(angular.isArray(logs)){
                return _.map(logs, getID);
            }
        };

        self.removeDuplicates = function(ids, logs){
            var checkDuplicate = function(log){
                if(angular.isObject(log)  && !_.contains(ids, log.id)){
                    return log;
                }
            };
            if(angular.isArray(logs) && angular.isArray(ids)){
                return _.remove(logs, checkDuplicate);
            }
        };
        self.storeLogs = function(logs){
            store.set(CoreConstants.storeKeys.logs, logs);
            return logs;
        };
        self.setIncludeArchive = function(bool){
            store.set(CoreConstants.storeKeys.includeArchive, bool);
            return bool;
        };
        self.includeArchive = function(){
            return store.get(CoreConstants.storeKeys.includeArchive);
        };
        self.getActiveLogs = function(){
            var logs = store.get(CoreConstants.storeKeys.logs);
            return logs;
        };

        self.archiveLogs = function(logs){
            var arch = store.get(CoreConstants.storeKeys.archivedLogs);
            var _arch =  _.uniq(_.union(logs,arch), 'id');
            store.set(CoreConstants.storeKeys.archivedLogs, _arch);
            return _arch;
        };
        self.getArchivedLogs = function(){
            var arch = store.get(CoreConstants.storeKeys.archivedLogs);
            return arch;
        };

        self.getAllLogs = function(){
            var arch = store.get(CoreConstants.storeKeys.archivedLogs);
            var logs = store.get(CoreConstants.storeKeys.logs);
            //var archLogs = self.removeDuplicates(self.getLogIds(logs), arch);
            var all = _.uniq(_.union(logs,arch), 'id');
            return all;
        };

        self.deleteActiveLogs = function(){
            var all = self.getAllLogs();
            self.archiveLogs(all);
            self.storeLogs([]);
            return all;
        };

        self.deleteStores = function(){
            var keys = [
                CoreConstants.storeKeys.archivedLogs,
                CoreConstants.storeKeys.logs,
                CoreConstants.storeKeys.includeArchive
            ];
            angular.forEach(keys, function(val){
                store.remove(val);
            });
        };



        self.deleteRemoteLogs = function(){
            var deferred = $q.defer();
            $http.delete('/meda/verification/logs')
                .success(function(data, status, headers, config) {
                    // this callback will be called asynchronously
                    // when the response is available
                    deferred.resolve(true);
                }).
                error(function(data, status, headers, config) {
                    // called asynchronously if an error occurs
                    // or server returns response with an error status
                    $log.log('err: ', data);
                    deferred.reject('logs were not deleted');
                });

            return deferred.promise;
        };

        self.getRemoteLogs= function(){
            var deferred = $q.defer();
            $http.get(  '/meda/verification/logs').
                success(function(data, status, headers, config) {
                    // this callback will be called asynchronously
                    // when the response is available
                    deferred.resolve(data);
                }).
                error(function(data, status, headers, config) {
                    // called asynchronously if an error occurs
                    // or server returns response with an error status
                    deferred.reject(data);
                });
            return deferred.promise;
        };
    }
]);

angular.module('core').service('CoreService', [
    '$q',
    '$http',
    function($q, $http) {
        var self= this;

        self.getOutputKeys = function(log){
            if(angular.isObject(log) &&
                angular.isObject(log.outputs)){
                var list = Object.keys(log.outputs).join(', ');
                return list;
            }
            return 'none';
        };
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
            return deferred.promise;
        };

        var customFilter = {
            'end_point_type':function(item, crit, val){
                return _.contains(item.http[crit].toLowerCase(), val.toLowerCase());
            },
            'member_id': function(item, crit, val){
                var val1 =  (item['profile_id']) ? item['profile_id'].toLowerCase() : null;
                var val2 =  (val) ? val.toLowerCase() : null;
                return _.contains(val1 , val2);
            },
            'outputs': function(item, crit, val){
                var outs = self.getOutputKeys(item).toLowerCase();
                return _.contains(outs , val);
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
            var custom = ['end_point_type', 'member_id', 'outputs'];
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

