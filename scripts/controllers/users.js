'use strict';

/**
 * @ngdoc function
 * @name cityZenLights.controller:UsersCtrl
 * @description
 * # UsersCtrl
 * Controller of cityZenLights
 */
angular.module('cityZenLights')
.controller('UsersCtrl', function($scope, $log, $filter, Leaflet, $timeout, Data, $sessionStorage) {

	if ($sessionStorage.id != null) {

    	$log.info('Users Controller loaded!');
    	$scope.users = Data.users();
    	$scope.currentUser = {};
    	$scope.userTypes = [
    		{value: 0, text: 'Administrator'},
    		{value: 1, text: 'Power User'},
    		{value: 2, text: 'User'},
  		]; 

  		$scope.showType = function(type) {

    		var selected = [];
		    if(type) {
		    	selected = $filter('filter')($scope.userTypes, {value: type});
		    }
    		return selected.length ? selected[0].text : 'Not set';
  		};

    	$scope.saveUser = function(data, id) {
			
			angular.extend(data, {id: id});
			if (id == 0) {
				Data.saveUser(data).then(function (usrRes) {
					if (usrRes.inserted) {
						var temp = $filter('filter')($scope.users, {id: 0}, true)[0];
						temp.id = usrRes.inserted;
					} else {
						alert('Η αποθήκευση απέτυχε!');
						$scope.users = _.reject($scope.users, function(item){ return item.id == 0; });
					}
				}, function (usrErr) {
					$log.error(usrErr);
				})
			} else {
				Data.updateUser(data).then(function (usrRes) {
					if(!usrRes.updated){
						alert('Η αποθήκευση απέτυχε!');
					}
				}, function (usrErr) {
					$log.error(usrErr);
				})
			}
		};

		$scope.afterSaveCurrentUser = function () {

			Data.updateUser($scope.currentUser).then(function (usrRes) {
				if(!usrRes.updated){
					alert('Η αποθήκευση απέτυχε!');
					return 'error';
				}else{
					return true;
				}
			}, function (usrErr) {
				$log.error(usrErr);
				return 'error';
			})
		}

		$scope.removeUser = function(id) {
			
			Data.deleteUser(id).then(function (usrRes) {
				if (usrRes.deleted) {
					$scope.users = _.reject($scope.users, function(item){ return item.id == id; });
				}
			}, function (usrErr) {
				$log.error(usrErr);
			})
		};

		$scope.addUser = function() {

			$scope.inserted = {
				id: 0,
				name: '',
				username: '',
				password: '',
				email: '',
				phone: '',
				type: 0
			};
			$scope.users.push($scope.inserted);
		};

    	Data.getUsers().then(function (res) {
    		
    		$scope.users = res;
    		$scope.currentUser = $filter('filter')($scope.users, {id: $scope.user.id}, true)[0];
    	}, function (err) {
    		$log.error(err);
    	})
    }
});