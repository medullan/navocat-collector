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

        self.tokenExists = function(){
            var token = self.getToken();
            if(angular.isString(token) && token.length > 0){
                return true;
            }
            return false;
        };

        self.deleteStores = function(){
            var keys = [
                CoreConstants.storeKeys.token,
                CoreConstants.storeKeys.recentLogOut
            ];
            angular.forEach(keys, function(val){
                store.remove(val);
            });
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
                var toRemove =  _.remove(angular.copy(logs), checkDuplicate);
                return toRemove;
            }
        };
        self.storeLogs = function(logs){
            store.set(CoreConstants.storeKeys.logs, logs);
            return logs;
        };
        self.storeFilterOptions = function(filterKey, filterValue){
            var opt = {key: filterKey || '', value: filterValue || ''};
            store.set(CoreConstants.storeKeys.filterOptions, opt);
            return opt;
        };

        self.getFilterOptions = function(){
            var opt = store.get(CoreConstants.storeKeys.filterOptions);
            return opt;
        };
        self.setIncludeArchive = function(bool){
            store.set(CoreConstants.storeKeys.includeArchive, bool);
            return bool;
        };
        self.includeArchive = function(){
            return store.get(CoreConstants.storeKeys.includeArchive);
        };

        self.setFilterToggle = function(bool){
            store.set(CoreConstants.storeKeys.filterToggle, bool);
            return bool;
        };
        self.getFilterToggle = function(){
            return store.get(CoreConstants.storeKeys.filterToggle);
        };

        self.getActiveLogs = function(){
            var logs = store.get(CoreConstants.storeKeys.logs);
            return logs;
        };

        self.archiveLogs = function(logs){
            var arch = store.get(CoreConstants.storeKeys.archivedLogs);
            arch =  _.union(logs,arch);
            var archLogs = self.removeDuplicates(self.getLogIds(self.getActiveLogs()), arch);
            arch =  _.uniq(archLogs, 'id');
            angular.forEach(arch, function(value, key){
                if(angular.isObject(value)){
                    value.$archived = true;
                    arch[key] = value;
                }
            });
            store.set(CoreConstants.storeKeys.archivedLogs, arch);
            return arch;
        };
        self.getArchivedLogs = function(){
            var archLogs = store.get(CoreConstants.storeKeys.archivedLogs);
            //var archLogs = self.removeDuplicates(self.getLogIds(self.getActiveLogs()), arch);
            return archLogs;
        };

        self.getAllLogs = function(){
            var arch = store.get(CoreConstants.storeKeys.archivedLogs);
            var logs = store.get(CoreConstants.storeKeys.logs);
            var all = (_.union(logs,arch));
            return all;
        };

        self.deleteActiveLogs = function(){
            var all = self.getAllLogs();
            self.storeLogs([]); // must set to empty before archiving
            self.archiveLogs(all);
            return all;
        };

        self.deleteStores = function(){
            var keys = [
                CoreConstants.storeKeys.archivedLogs,
                CoreConstants.storeKeys.logs,
                CoreConstants.storeKeys.includeArchive,
                CoreConstants.storeKeys.filterOptions,
                CoreConstants.storeKeys.filterToggle
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
            var filterOpt = self.getFilterOptions();
            filterOpt = filterOpt || {key: '', value: ''};
            var apiUrl = '/meda/verification/logs?filter_key='+ filterOpt.key +'&filter_value='+ filterOpt.value +'';

            $http.get(apiUrl).
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
            },
            'contain': function(item, crit, val){
                var outs = JSON.stringify(item).toLowerCase();
                return _.contains(outs , val);
            }
        };
        var extraData = {
            'member_id': function( crit, val){
                var deferred = $q.defer();
                self.verify(val).then(function(data){
                    var result = {value: data.hash};
                    deferred.resolve(result);
                });
                return deferred.promise;
            }
        };

        var advancedFilter = {
            'date': function(item, pred){
                var logDate = item.http.start_time;
                if(pred){
                    var result = true;
                    if(pred.criteria == 'before'){
                        result = moment(logDate).isBefore(pred.firstValue, 'day');
                    }else if(pred.criteria == 'after'){
                        result = moment(logDate).isAfter(pred.firstValue, 'day');
                    }else if(pred.criteria == 'between'){
                        result = moment(logDate).isAfter(pred.firstValue) && moment(logDate).isBefore(moment(pred.secondValue).add(1,'d'));
                    }
                    console.log('date pred', logDate, pred.firstValue, result);
                    return result;
                }


                return true;
            }
        };

        var getPredValue = function(item, pred){
            if(pred && pred.advancedFilterToggle && pred.type){
                var result = advancedFilter[pred.type](item, pred);
                //console.log('pred: ', result);
                return result;
            }
            return true;
        };
        function query(json, criteria, value, pred) {
            var custom = ['end_point_type', 'member_id', 'outputs', 'contain'];
            return Enumerable.From(json)
                .Where(function (item) {
                    var result = false;
                    var predValue = getPredValue(item, pred);
                    if (_.contains(custom, criteria)) {
                        result = customFilter[criteria](item, criteria, value, pred) && predValue;
                    } else {
                        result = _.contains(item[criteria].toLowerCase(), value.toLowerCase()) && predValue;
                    }
                    return result;
                })
                .ToArray();
        }

        self.filter= function(json, criteria, value, pred){
            var deferred = $q.defer();
            var data = ['member_id'];
            if(_.contains(data, criteria)){
                extraData[criteria](criteria, value).then(function(data){
                    var result = query(json, criteria, data.value, pred);
                    var data = {results: result, data:data};
                    deferred.resolve(data) ;
                });
            }else{
                var result = query(json, criteria, value, pred);
                var data = {results: result, data:{value:value, criteria: criteria}};
                deferred.resolve(data) ;
            }

            return deferred.promise;
        };
    }
]);

