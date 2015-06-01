'use strict';

// Init the application configuration module for AngularJS application
var ApplicationConfiguration = (function() {
    // Init module configuration options
    var applicationModuleName = 'collector';
    var applicationModuleVendorDependencies = [
         'ui.router', 'ui.bootstrap'
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
angular.module(ApplicationConfiguration.applicationModuleName, ApplicationConfiguration.applicationModuleVendorDependencies);

// Setting HTML5 Location Mode
angular.module(ApplicationConfiguration.applicationModuleName).config(['$locationProvider',
    function($locationProvider) {
        $locationProvider.hashPrefix('!');
    }
]);

//Then define the init function for starting up the application
angular.element(document).ready(function() {
    //Fixing facebook bug with redirect
    if (window.location.hash === '#_=_') window.location.hash = '#!';

    //Then init the app
    angular.bootstrap(document, [ApplicationConfiguration.applicationModuleName]);
});

ApplicationConfiguration.registerModule('core');

// Setting up route
angular.module('core').config([
    '$stateProvider',
    '$urlRouterProvider',
    'CoreConstants',
    function($stateProvider, $urlRouterProvider, CoreConstants) {
        // Redirect to home view when route not found
        $urlRouterProvider.otherwise('/');

        // Home state routing
        $stateProvider.
            state('home', {
                url: '/',
                templateUrl: CoreConstants.assetBaseUrl + '/views/home.client.view.html',
                controller: 'HomeCtrl'
            });

        $stateProvider.state('logs',{
            url: '/logs',
            templateUrl: CoreConstants.assetBaseUrl + '/views/logs.client.view.html',
            controller: 'LogCtrl'
        });
    }
]);

angular.module('core').constant('CoreConstants', (function(){
    var appName = ApplicationConfiguration.applicationModuleName;

    //Default values for CoreConstants
    var constant = {
        assetBaseUrl: 'verifier/assets',
        appName: appName
    };
    return constant;
})());
