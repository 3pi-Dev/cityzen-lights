'use strict';

/**
 * @ngdoc function
 * @name yapp.controller:MainCtrl
 * @description
 * # MainCtrl
 * Controller of yapp
 */
angular.module('cityZenLights')
  .controller('LoginCtrl', function($scope, $http, $location, $log, AuthService, $sessionStorage) {

    $log.info('Login Controller loaded!');

  	$scope.$session = $sessionStorage;

    $scope.username = '';
    $scope.password = '';

    $scope.submit = function() {

    	AuthService.login($scope.username,$scope.password).then(function (res) {
        $log.debug(res);
    		if (res.login) {
            $scope.$session.id = res.id;
				    $scope.$session.name = res.user;
            $scope.$session.type = res.type;
      			$location.path('/dashboard');
    		}else {
            alert("Πρόβλημα στην είσοδο, ξαναπροσπαθήστε αργότερα!");
        }
    	}, function (err) {
    		$log.error(err);
    	})
      return false;
    }
  });