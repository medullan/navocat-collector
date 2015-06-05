'use strict';

// Init the application configuration module for AngularJS application
var ApplicationConfiguration = (function() {
    // Init module configuration options
    var applicationModuleName = 'collector';
    var applicationModuleVendorDependencies = [
         'ui.router', 'ui.bootstrap', 'angular-storage',
        'duScroll', 'permission', 'ngClipboard','ngAnimate', 'toastr'
    ];

    // Add a new vertical module
    var registerModule = function(moduleName, dependencies) {
        // Create angular module
        angular.module(moduleName, dependencies || []);

        // Add the module to the AngularJS configuration file
        angular.module(applicationModuleName).requires.push(moduleName);
    };

    return {
        applicationModuleName: applicationModuleName,
        applicationModuleVendorDependencies: applicationModuleVendorDependencies,
        registerModule: registerModule
    };
})();

//Start by defining the main module and adding the module dependencies
var mainApp = angular.module(ApplicationConfiguration.applicationModuleName, ApplicationConfiguration.applicationModuleVendorDependencies);

// Setting HTML5 Location Mode
angular.module(ApplicationConfiguration.applicationModuleName).config(['$locationProvider',
    function($locationProvider) {
        $locationProvider.hashPrefix('!');
    }
]);
angular.module(ApplicationConfiguration.applicationModuleName).config(function ($httpProvider) {
    //$httpProvider.responseInterceptors.push('httpInterceptor');
    $httpProvider.interceptors.push('myHttpInterceptor');

});


//Then define the init function for starting up the application
angular.element(document).ready(function() {
    //Fixing facebook bug with redirect
    if (window.location.hash === '#_=_') window.location.hash = '#!';

    //Then init the app
    angular.bootstrap(document, [ApplicationConfiguration.applicationModuleName]);
});

ApplicationConfiguration.registerModule('core');

angular.module('core').run([
    'Permission',
    'UserService',
    function (Permission, UserService) {
        // Define anonymous role
        Permission.defineRole('anonymous', function (stateParams) {
            // If the returned value is *truthy* then the user has the role, otherwise they don't
            if (!UserService.tokenExists()) {
                return true; // Is anonymous
            }
            return false;
        });

        Permission.defineRole('user', function (stateParams) {
            // If the returned value is *truthy* then the user has the role, otherwise they don't
            if (UserService.tokenExists()) {
                return true; // Is user
            }
            return false;
        });
        Permission.defineRole('recentLogOut', function (stateParams) {
            // If the returned value is *truthy* then the user has the role, otherwise they don't
            if (UserService.recentLogOut()) {
                return true; // Is recentLogOut
            }
            return false;
        });



    }]);
// Setting up route
angular.module('core').config([
    '$stateProvider',
    '$urlRouterProvider',
    'CoreConstants',
    'ngClipProvider',
    function($stateProvider, $urlRouterProvider, CoreConstants, ngClipProvider) {
        // Redirect to home view when route not found
        $urlRouterProvider.otherwise('/');

        // Home state routing
        $stateProvider.
            state('home', {
                url: '/',
                templateUrl: CoreConstants.assetBaseUrl + '/views/home.client.view.html',
                controller: 'HomeCtrl'
            })
            .state('done',{
                url: '/done',
                templateUrl: CoreConstants.assetBaseUrl + '/views/done.client.view.html',
                controller: 'DoneCtrl',
                data: {
                    permissions: {
                        only: ['recentLogOut'],
                        redirectTo: 'home'
                    }
                }
            })
            .state('logs',{
                url: '/logs',
                templateUrl: CoreConstants.assetBaseUrl + '/views/logs.client.view.html',
                controller: 'LogCtrl',
                data: {
                    permissions: {
                        except: ['anonymous'],
                        redirectTo: 'home'
                    }
                }
        });

        ngClipProvider.setPath( CoreConstants.assetBaseUrl + "/lib/zeroclipboard/ZeroClipboard.swf");

    }
]);

angular.module('core').constant('CoreConstants', (function(){
    var appName = ApplicationConfiguration.applicationModuleName;

    //Default values for CoreConstants
    var constant = {
        assetBaseUrl: 'verifier/assets',
        appName: appName,
        storeKeys: {
            logs: 'logs',
            archivedLogs: 'archivedLogs',
            includeArchive: 'includeArchive',
            token: 'token',
            recentLogOut: 'recentLogOut'
        }
    };
    return constant;
})());
