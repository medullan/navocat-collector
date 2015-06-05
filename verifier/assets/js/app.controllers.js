/**
 * Created by layton on 5/28/15.
 */

angular.module('core').controller('HomeCtrl', [
    '$scope',
    'UserService',
    '$state',
    '$log',
    function($scope, UserService, $state, $log) {
        $scope.loginModel = {key: null};
        $scope.UserService = UserService;

        $scope.auth = function(key){
            UserService.verifyPrivateKey(key).then(function(data){
                    UserService.storeToken(data.key);
                    $state.go('logs');
            },
            function(data){
                $scope.hasError = true;
                $scope.status = data.status;
            });
        };

    }
]);

angular.module('core').controller('DoneCtrl', [
    '$scope',
    'UserService',
    '$state',
    '$log',
    'LogStoreService',
    'CoreConstants',
    'toastr',
    function($scope, UserService, $state, $log, LogStoreService, CoreConstants, toastr) {
        $scope.loginModel = {key: null};
        $scope.UserService = UserService;


        $scope.archivedLogs = LogStoreService.deleteActiveLogs();


        //LogStoreService.deleteRemoteLogs().then(function(data){
        //
        //    //cleanup
        //    UserService.deleteStores();
        //    LogStoreService.deleteStores();
        //    $log.log('logs deleted?', data);
        //});

        $scope.jsonToString = function(val){
            return JSON.stringify(val);
        };

        $scope.copyDone = function(){
            toastr.info('JSON copied to clipboard!', 'Information');
        };



    }
]);

angular.module('core').controller('SiteCtrl', [
    '$scope',
    'UserService',
    '$state',
    '$log',
    'LogStoreService',
    'CoreConstants',
    '$modal',
    function($scope, UserService, $state, $log, LogStoreService, CoreConstants, $modal) {

        $scope.UserService = UserService;

        $scope.confirmEndSession = function(size){
            var modalInstance = $modal.open({
                animation: true,
                templateUrl: CoreConstants.assetBaseUrl + '/views/partials/confirmclear.html',
                controller: 'ConfirmModalCtrl',
                size: size,
                resolve: {
                    info: function () {
                        var info = {
                            messages: [
                                'You will be logged out',
                                'Your logs will be deleted from the server',
                                'You will get an opportunity to see the archived logs ONLY once; after which they will be lost forever',
                                'If you wish to save the logs please copy them before moving away from the next page'
                            ]
                        };
                        return info;
                    }
                }
            });

            modalInstance.result.then(function (confirm) {
                if(confirm){
                    UserService.setRecentLogOut(true);
                    $state.go('done');
                }
            }, function () {
                $log.info('ConfirmClear Modal dismissed at: ' + new Date());
            });
        };



    }
]);

angular.module('core').controller('ConfirmModalCtrl', [
    '$scope',
    '$modalInstance',
    'info',
    function ($scope, $modalInstance, info) {
        $scope.info = info;
        $scope.info.continueBtnTxt = $scope.info.continueBtnTxt || 'Continue';
        $scope.ok = function () {
            $modalInstance.close(true);
        };

        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        };
    }
]);

angular.module('core').controller('ImportModalCtrl', [
    '$scope',
    '$modalInstance',
    'info',
    'toastr',
    'LogStoreService',
    function ($scope, $modalInstance, info, toastr, LogStoreService) {
        $scope.info = info;

        $scope.import = function(json){
            var logs = null;
            try{
                if(angular.isString(json) && json.length > 0){
                    logs = JSON.parse(json);
                    if(angular.isArray(logs)){
                        if(logs.length > 0){
                            LogStoreService.archiveLogs(logs);
                            toastr.success('Logs imported!');
                            return true;
                        }else{
                            toastr.warning('No logs were imported!');
                        }
                    }else{
                        toastr.warning('The JSON must be an array of logs');
                    }
                }else{
                    toastr.error('Valid JSON must be entered');
                }

            }catch(e){
                toastr.error(e.message);
            }
        };

        $scope.ok = function (jsonString) {
            var result = $scope.import(jsonString);
            if(result){
                $modalInstance.close(result);
            }
        };

        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        };
    }
]);

angular.module('core').controller('LogCtrl', [
    '$scope',
    '$log',
    'CoreService',
    'LogStoreService',
    'CoreConstants',
    '$modal',
    'toastr',
    'cfpLoadingBar',
    function($scope, $log, CoreService, LogStoreService, CoreConstants, $modal, toastr, cfpLoadingBar) {
        $scope.pageStatus = 'loading';
        var toggleText = {
            include: 'Include Archived Logs',
            remove: 'Remove Archived Logs'
        };
        var setToggleText = function(){
            $scope.toggleIncludeText = ($scope.includeArchive)? toggleText.remove: toggleText.include;
        };
        var updateLogs = function(){
            var logs = [];
            $scope.activeLogs = LogStoreService.getActiveLogs() || [];
            if($scope.includeArchive){
                logs = LogStoreService.getAllLogs() || [];
            }else{
                logs = $scope.activeLogs;
            }
            return logs;
        };
        $scope.logs = updateLogs();
        $scope.archivedLogs = LogStoreService.getArchivedLogs() || [];
        $scope.includeArchive = LogStoreService.includeArchive();
        setToggleText();
        $scope.UAParser=UAParser;
        $scope.logfilter = '';
        $scope.settings = {
            onlyOne: true
        };

        LogStoreService.getRemoteLogs().then(function(data){
                $scope.pageStatus = 'done';
                LogStoreService.storeLogs(data);
                $scope.logs = updateLogs();
            },
            function(data){
                $log.log('err: ', data);
                $scope.pageStatus = 'error';
            });

        $scope.openImport = function(size){
            var modalInstance = $modal.open({
                animation: true,
                templateUrl: CoreConstants.assetBaseUrl + '/views/partials/import.html',
                controller: 'ImportModalCtrl',
                size: size,
                resolve: {
                    info: function () {
                        var info = {
                            messages: [
                                'Clearing the logs will also delete all logs on the server.'
                            ]
                        };
                        return info;
                    }
                }
            });

            modalInstance.result.then(function (data) {

            }, function () {
                $log.info('ConfirmClear Modal dismissed at: ' + new Date());
            });
        };

        $scope.confirmClear = function(size){
            var modalInstance = $modal.open({
                animation: true,
                templateUrl: CoreConstants.assetBaseUrl + '/views/partials/confirmclear.html',
                controller: 'ConfirmModalCtrl',
                size: size,
                resolve: {
                    info: function () {
                        var info = {
                            messages: [
                                'Clearing the logs will also delete all logs on the server.'
                            ]
                        };
                        return info;
                    }
                }
            });

            modalInstance.result.then(function (clear) {
                if(clear){
                    $scope.clearLogs();
                }
            }, function () {
                $log.info('ConfirmClear Modal dismissed at: ' + new Date());
            });
        };

        $scope.clearLogs = function(){
            LogStoreService.deleteRemoteLogs().then(function(data){
                $scope.logs = [];
                LogStoreService.deleteActiveLogs();
                toastr.success('logs deleted!');
            },
            function(data){
                toastr.error('error deleting logs!');
            });
        };

        $scope.refreshLogs = function(){
            LogStoreService.getRemoteLogs().then(function(data){
                    LogStoreService.storeLogs(data);
                    $scope.logs = updateLogs();
                    toastr.success('logs refreshed!');
                },
                function(data){
                    toastr.error('error refreshing logs!');
                });
        };

        $scope.toggleIncludeArchive = function(){
            if(typeof $scope.includeArchive !== 'boolean'){
                $scope.includeArchive = true;
                $scope.toggleIncludeText = toggleText.remove;
            }else{
                $scope.includeArchive = !$scope.includeArchive;
            }
            setToggleText();
            LogStoreService.setIncludeArchive($scope.includeArchive);
            $scope.logs = updateLogs();
        };




        $scope.outputPresent =function(log, val){
            if(angular.isString(val) &&
                angular.isObject(log) &&
                log.outputs){
                 return !!log.outputs[val]
            }
            return false;
        };

        $scope.getOutputKeys= CoreService.getOutputKeys;

        $scope.searchOptions = [
            {id:2, val:'Member ID', prop:'member_id'},
            {id:4, val:'Collector Hit Type', prop:'type'},
            {id:4, val:'Endpoint Type', prop:'end_point_type'},
            {id:1, val:'Client ID', prop:'client_id'},
            {id:3, val:'Outputs' , prop:'outputs'},
            {id:3, val:'RVA ID' , prop:'id'},
        ];
        $scope.selected = { val: $scope.searchOptions[0] };

        $scope.clearFilter = function(value){
            if( _.trim(value).length === 0){
                $scope.logs = updateLogs();
            }
        };

        $scope.filter= function(criteria, value){
            if( value.length >0){
                cfpLoadingBar.start();
                cfpLoadingBar.inc();
                CoreService.filter(updateLogs(), criteria, value).then(function(data){
                    $scope.logs = data;
                    cfpLoadingBar.complete();
                },function(){
                    cfpLoadingBar.complete();
                });
            }else{
                $scope.clearFilter();
            }
        };


    }
]);