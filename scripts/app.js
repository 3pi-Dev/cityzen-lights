'use strict';

/**
 * @ngdoc overview
 * @name cityZenLights
 * @description
 * # cityZenLights
 *
 * Main module of the application.
 */
angular
  .module('cityZenLights', [
    'ui.router',
    'ui.bootstrap',
    'angular-loading-bar',
    'ngAnimate',
    'ngStorage',
    'angularSpinner',
    'ui.bootstrap.datetimepicker',
    'ui.toggle',
    'chart.js',
    'angularMoment',
    'xeditable'
  ])
  .config(function($stateProvider, $urlRouterProvider, usSpinnerConfigProvider, cfpLoadingBarProvider) {

    $urlRouterProvider.when('/dashboard', '/dashboard/overview');
    $urlRouterProvider.otherwise('/login');

    usSpinnerConfigProvider.setTheme('crimsoNice', {radius:15,width:6,length:0,color:'#4a2726',lines:17,scale:3,corners:1,opacity:0,rotate:0,speed:1.2,trail:50});
    usSpinnerConfigProvider.setTheme('crimsoNiceSmall', {radius:15,width:4,length:0,color:'#4a2726',lines:15,scale:2,corners:1,opacity:0,rotate:0,speed:1.1,trail:50});

    cfpLoadingBarProvider.includeSpinner = false;

    $stateProvider
      .state('base', {
        abstract: true,
        url: '',
        templateUrl: 'views/base.html'
      })
        .state('login', {
          url: '/login',
          parent: 'base',
          templateUrl: 'views/login.html',
          controller: 'LoginCtrl'
        })
        .state('logout', {
          url: '/logout',
          controller: function(AuthService) {
            AuthService.logout();
          }
        })
        .state('dashboard', {
          url: '/dashboard',
          parent: 'base',
          templateUrl: 'views/dashboard.html',
          controller: 'DashboardCtrl'
        })
          .state('overview', {
            url: '/overview',
            parent: 'dashboard',
            templateUrl: 'views/dashboard/overview.html',
            controller: 'OverviewCtrl'
          })
          .state('users', {
            url: '/users',
            parent: 'dashboard',
            templateUrl: 'views/dashboard/users.html',
            controller: 'UsersCtrl'
          })
          .state('report', {
            url: '/report',
            parent: 'dashboard',
            templateUrl: 'views/dashboard/report.html',
            controller: 'ReportCtrl',
            params: {
              reportID: null
            }
          })
          .state('lights', {
            url: '/lights',
            parent: 'dashboard',
            templateUrl: 'views/dashboard/overview.html',
            controller: 'LightsCtrl',
            params: {
              catID: null
            }
          })
  })
  .run(function(editableOptions) {
    editableOptions.theme = 'bs3';
  });