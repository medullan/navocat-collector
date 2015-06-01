/**
 * Created by layton on 5/28/15.
 */

angular.module('core').controller('HomeCtrl', [
    '$scope',
    function($scope) {
        // This provides Authentication context.
        $scope.loginModel = {key: null, address:null};
        $scope.validator = validator;
        $scope.isValidString = function(str){
            str = validator.trim(str);
            if(angular.isString(str) && str.length > 0){
                return true;
            }
            return false;
        }

    }
]);

angular.module('core').controller('SiteCtrl', [
    '$scope',
    '$http',
    function($scope, $http) {
        $scope.clearLogs = function(){
            $http.delete('/meda/verification/logs')
                .success(function(data, status, headers, config) {
                    // this callback will be called asynchronously
                    // when the response is available
                    $scope.logs =  null;
                }).
                error(function(data, status, headers, config) {
                    // called asynchronously if an error occurs
                    // or server returns response with an error status
                    $log.log('err: ', data)
                });
        }

    }
]);

angular.module('core').controller('LogCtrl', [
    '$scope',
    '$http',
    '$log',
    'VerifyMemberId',
    '$q',
    function($scope, $http, $log, VerifyMemberId, $q) {
        $scope.settings = {
            onlyOne: true
        };
        $scope.innerstatus= {open:true}
        $scope.UAParser=UAParser;
        $scope.logfilter = '';
        $scope.logs = $scope.fullList = [];
        $scope.outputPresent =function(log, val){
            if(angular.isString(val) &&
                angular.isObject(log) &&
                log.outputs){
                 return !!log.outputs[val]
            }
            return false;
        };

        $scope.getOutputKeys= function(log){
            if(angular.isObject(log) &&
                angular.isObject(log.outputs)){
                var list = Object.keys(log.outputs).join(', ');
                return list;
            }
            return 'none';
        };

        $scope.searchOptions = [
            {id:1, val:'Client ID', prop:'client_id'},
            {id:2, val:'Member ID', prop:'member_id'},
            {id:3, val:'RVA ID' , prop:'id'},
            {id:4, val:'Hit Type', prop:'type'},
            {id:4, val:'Endpoint Type', prop:'end_point_type'},
        ];
        $scope.selected = { val: $scope.searchOptions[3] };

        var customFilter = {
            'end_point_type':function(item, crit, val){
                return _.contains(item.http[crit].toLowerCase(), val.toLowerCase());
            },
            'member_id': function(item, crit, val){
                var result =  false;
                var result = VerifyMemberId.verify(val);

                console.log(result);
                return result;
            }
        };

        $scope.filter= function(criteria, value){
            if(value && value.length >0){
                VerifyMemberId.filter($scope.fullList, criteria, value).then(function(data){
                    $scope.logs = data;
                });
            }else{
                $scope.logs = $scope.fullList;
            }


        };


        $http.get(  '/meda/verification/logs').
            success(function(data, status, headers, config) {
                // this callback will be called asynchronously
                // when the response is available
                $scope.logs = $scope.fullList = data;
            }).
            error(function(data, status, headers, config) {
                // called asynchronously if an error occurs
                // or server returns response with an error status
                $log.log('err: ', data)
            });

    }
]);