'use strict';

/**
 * @ngdoc function
 * @name cityZenLights.controller:LightsCtrl
 * @description
 * # LightsCtrl
 * Controller of cityZenLights
 */
angular.module('cityZenLights')
.controller('LightsCtrl', function($scope, $state, $stateParams, $location, $uibModal, $log, Leaflet, $timeout, $filter) {
    
    if($stateParams.catID != null){

        $log.info('Lights Controller loaded!');

        var leaf = Leaflet;
        var map = {};
        var bounds = [];
        var area = $stateParams.catID;
        $scope.selectedArea = $filter('filter')($scope.areas, {id: area}, true)[0];

        $scope.openLightSettings = function (item) {
            var modalInstance = $uibModal.open({
                animation: true,
                size: 'lg',
                templateUrl: 'settings2.html',
                controller: 'LightStgCtrl',
                resolve: {
                    light: function () {
                        return item;
                    }
                }
            });
        }

        map = leaf.showmap('map',[39.5203614, 22.6116068],7,true);
        $timeout(function () {
            angular.forEach($scope.selectedArea.lights, function(value, key){
                var type = $filter('filter')($scope.lightTypes, {id: value.type}, true)[0];
                var temp = '<div class="text-danger">Ιστός '+value.id+'<br/>Τύπος: '+type.title+'<br/>Λαμπτήρες: '+value.lamps.length+'<br/>';
                
                var marker = leaf.addmarker(map,value.position,temp,1);
                if ($scope.user.type != 2) {
                    marker.on('click',function(){
                        $scope.openLightSettings(value);
                    });
                }
                bounds.push(value.position);
            });
            leaf.fitLayers(map,bounds);
        },500);
    } else {
        $location.path('dashboard');
    }
});