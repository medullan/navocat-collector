/**
 * Created by layton on 5/28/15.
 */

angular.module('core').controller('HomeCtrl', [
    '$scope',
    'UserService',
    '$state',
    '$log',
    'toastr',
    'LogStoreService',
    function($scope, UserService, $state, $log, toastr, LogStoreService) {
        $scope.loginModel = {key: null};
        $scope.UserService = UserService;
        $scope.LogStoreService = LogStoreService;
        if(UserService.tokenExists()){
            $state.go('logs');
        }

        $scope.auth = function(key){
            UserService.verifyPrivateKey(key).then(function(data){
                    UserService.storeToken(data.key);
                    LogStoreService.setFilterToggle(false);
                    $state.go('logs');
            },
            function(data){
                toastr.error('There was an error verifying your key: ' + data.status.toUpperCase());
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
        $scope.UserService = UserService;
        $scope.archivedLogs = _.uniq(LogStoreService.deleteActiveLogs(), 'id');
        UserService.deleteStores();
        LogStoreService.deleteStores();
        //LogStoreService.deleteRemoteLogs().then(function(data){
        //    //cleanup
        //
        //    $log.log('logs deleted?', data);
        //});

        $scope.jsonToString = function(val){
            return JSON.stringify(val);
        };
        $scope.getJsonString = function(){
            return angular.element('#hidden-elem').text();
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
                            title: 'Are you sure you want to end the session?',
                            leadMessage: 'By ending the session and selecting \'Continue\':' ,
                            closingMessage: 'To save a copy of the logs, use the \'Copy JSON\' feature on the next screen before you close your browser window. This JSON will include your recent log activity and all logs that were imported.',
                            messages: [
                                'You will be logged out of the Collector Verifier',
                                //'Your logs will be deleted from the server and cannot be recovered'
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
        $scope.info.title = $scope.info.title || 'Are you sure?';
        $scope.ok = function () {
            $modalInstance.close(true);
        };

        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        };
    }
]);

angular.module('core').controller('MainFilterModalCtrl', [
    '$scope',
    '$modalInstance',
    'info',
    'toastr',
    'LogStoreService',
    function ($scope, $modalInstance, info, toastr, LogStoreService) {
        $scope.info = info;
        $scope.info.continueBtnTxt = $scope.info.continueBtnTxt || 'Continue';
        $scope.info.title = $scope.info.title || 'Are you sure?';
        $scope.filterOptions = [
            {val:'Member ID', prop:'member_id', serverId:'mid'},
            {val:'Client ID', prop:'client_id', serverId:'cid'},
            {val:'Profile ID',prop:'profile_id', serverId:'pid'}
        ];
        $scope.filterOpt = LogStoreService.getFilterOptions() || {key: null, value: null};
        var index = _.findIndex($scope.filterOptions, function(chr) {
            return chr.serverId == $scope.filterOpt.key;
        });
        var selected = null;
        if(index != -1) selected = $scope.filterOptions[index];
        $scope.selectedOpt = selected || $scope.filterOptions[0];

        $scope.ok = function (value) {
            if(angular.isString(value) && value.length > 0){
                var filterOpts = {key:$scope.selectedOpt.serverId, value: value };
                console.log($scope.selectedOpt.prop, value, filterOpts);
                $modalInstance.close(filterOpts);
            }else{
                toastr.warning('Please enter a value to continue!');
            }
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
                            var archive = LogStoreService.getArchivedLogs() || [];
                            var logs = LogStoreService.archiveLogs(logs) || [];
                            toastr.success((logs.length-archive.length || 0) + ' Log(s) Imported!');
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
                $scope.hasErrors = true;
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
            include: 'Show Archived Logs',
            remove: 'Hide Archived Logs'
        };
        $scope.LogStoreService = LogStoreService;
        var setToggleText = function(){
            $scope.toggleIncludeText = ($scope.includeArchive)? toggleText.remove: toggleText.include;
        };
        var updateLogs = function(){
            var logs = [];
            $scope.activeLogs = LogStoreService.getActiveLogs() || [];
            var archivedLogs = LogStoreService.getArchivedLogs() || [];
            //$scope.archivedLogs = LogStoreService.removeDuplicates(LogStoreService.getLogIds(LogStoreService.getActiveLogs()), archivedLogs);
            $scope.archivedLogs = (archivedLogs);
            if($scope.includeArchive){
                logs = _.uniq(LogStoreService.getAllLogs(), 'id') || [];
            }else{
                logs = $scope.activeLogs;
            }
            return logs;
        };
        $scope.sortType     = 'http.start_time'; // set the default sort type
        $scope.sortReverse  = true;
        $scope.logs = updateLogs();
        $scope.includeArchive = LogStoreService.includeArchive();
        setToggleText();
        $scope.UAParser=UAParser;
        $scope.logfilter = '';
        $scope.settings = {
            onlyOne: true
        };

        $scope.openImport = function(size){
            var modalInstance = $modal.open({
                animation: true,
                templateUrl: CoreConstants.assetBaseUrl + '/views/partials/import.html',
                controller: 'ImportModalCtrl',
                size: size,
                resolve: {
                    info: function () {
                        var info = {
                        };
                        return info;
                    }
                }
            });



            modalInstance.result.then(function (data) {
                $scope.logs = updateLogs();
            }, function () {
                $log.info('ConfirmClear Modal dismissed at: ' + new Date());
            });
        };

        var getLogs = function(){
            LogStoreService.getRemoteLogs().then(function(data){
                    LogStoreService.deleteActiveLogs();
                    LogStoreService.storeLogs(data);
                    $scope.logs = updateLogs();
                    $scope.pageStatus = 'done';
                },
                function(data){
                    $log.log('err: ', data);
                    $scope.pageStatus = 'error';
                });
        };
        if(LogStoreService.getFilterToggle()){
            getLogs();
        }

        $scope.openMainFilterModal = function(size){
            var modalInstance = $modal.open({
                animation: true,
                templateUrl: CoreConstants.assetBaseUrl + '/views/partials/mainfilter.html',
                controller: 'MainFilterModalCtrl',
                size: size,
                resolve: {
                    info: function () {
                        var info = {
                        };
                        return info;
                    }
                }
            });

            modalInstance.result.then(function (data) {
                LogStoreService.setFilterToggle(true);
                LogStoreService.storeFilterOptions(data.key, data.value);
                getLogs();


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
                            title: 'Are you sure you want to clear the logs?',
                            leadMessage: 'By choosing this option: ' ,
                            closingMessage: 'To view the archived logs, use the \'Show Archived Logs\' feature to add archived logs to the main list.',
                            messages: [
                                'You will be deleting the logs on the server',
                                'The logs will remain archived in the Collector Verifier until you end the session'
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
                    $scope.includeArchive = LogStoreService.setIncludeArchive(false);
                    $scope.logs = updateLogs();
                    LogStoreService.deleteActiveLogs();
                    toastr.success('logs deleted!');
            },
            function(data){
                toastr.error('error deleting logs!');
            });
        };

        $scope.refreshLogs = function(){
            LogStoreService.getRemoteLogs().then(function(data){
                    LogStoreService.deleteActiveLogs();
                    LogStoreService.storeLogs(data);
                    $scope.logs = updateLogs();
                    toastr.success('Log(s) Refreshed!');
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
            {val:'Contain', prop:'contain'},
            //{val:'Member ID', prop:'member_id'},
            {val:'Collector Hit Type', prop:'type'},
            {val:'Client ID', prop:'client_id'},
            {val:'Endpoint Type', prop:'end_point_type'},
            {val:'Outputs' , prop:'outputs'},
            //{val:'Date' , prop:'start_time'},
            {val:'RVA ID' , prop:'id'},
        ];
        $scope.selected =  $scope.searchOptions[0] ;

        $scope.datePredOptions = [
            {id:3, val:'Between', prop:'between'},
            {id:1, val:'Before', prop:'before'},
            {id:2, val:'After', prop:'after'},
        ];
        $scope.selectedDatePred = $scope.datePredOptions[0];

        $scope.clearFilter = function(value){
            if( _.trim(value).length === 0){
                $scope.logs = updateLogs();
            }
        };

        $scope.filter= function(criteria, value, form){
            $scope.searchValue = null;
            if( value.length >0){
                cfpLoadingBar.start();
                cfpLoadingBar.inc();
                var pred = {
                    type: 'date',
                    advancedFilterToggle: form.advancedFilterToggle.$viewValue,
                    firstValue: (form.firstDate.$viewValue),
                    secondValue: (form.secondDate.$viewValue),
                    criteria: form.selectedDatePred.$viewValue.prop
                };

                CoreService.filter(updateLogs(), criteria, value, pred).then(function(data){
                    $scope.pageStatus = 'loading';
                    $scope.logs = [];
                    $scope.logs = data.results;
                    cfpLoadingBar.complete();
                    $scope.pageStatus = 'done';
                    if(criteria.toLowerCase() === 'contain'){
                        $scope.searchValue = value;
                    }
                },function(){
                    cfpLoadingBar.complete();
                });
            }else{
                $scope.clearFilter();
            }
        };

        $scope.advancedFilter = false;

        $scope.datepickers = {
            'one':{
                open:false,
            },
            'two': {
                open:false
            }

        }
        $scope.today = function() {
            return $scope.dt = new Date();
        };
        $scope.secondDate = $scope.today();

        $scope.clear = function () {
            $scope.dt = null;
        };
        // Disable weekend selection
        $scope.disabled = function(date, mode) {
            return ( mode === 'day' && ( date.getDay() === 0 || date.getDay() === 6 ) );
        };

        $scope.toggleMin = function() {
            $scope.minDate = $scope.minDate ? null : new Date();
        };
        $scope.toggleMin();

        $scope.open = function($event, name) {
            $event.preventDefault();
            $event.stopPropagation();

            $scope.datepickers[name].opened = true;
        };
        $scope.dateOptions = {
            formatYear: 'yy',
            startingDay: 1,
            showWeeks:false,
            showButtonBar:false
        };

        $scope.formats = ['dd-MMMM-yyyy', 'yyyy/MM/dd', 'dd.MM.yyyy', 'shortDate'];
        $scope.format = $scope.formats[0];


        var tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        var afterTomorrow = new Date();
        afterTomorrow.setDate(tomorrow.getDate() + 2);
        $scope.events =
            [
                {
                    date: tomorrow,
                    status: 'full'
                },
                {
                    date: afterTomorrow,
                    status: 'partially'
                }
            ];

        $scope.getDayClass = function(date, mode) {
            if (mode === 'day') {
                var dayToCheck = new Date(date).setHours(0,0,0,0);

                for (var i=0;i<$scope.events.length;i++){
                    var currentDay = new Date($scope.events[i].date).setHours(0,0,0,0);

                    if (dayToCheck === currentDay) {
                        return $scope.events[i].status;
                    }
                }
            }

            return '';
        };


    }
]);