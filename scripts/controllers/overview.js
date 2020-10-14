'use strict';

/**
 * @ngdoc function
 * @name cityZenLights.controller:OverviewCtrl
 * @description
 * # OverviewCtrl
 * Controller of cityZenLights
 */
angular.module('cityZenLights')
.controller('OverviewCtrl', function($scope, $log, $sessionStorage, $filter, Leaflet, $timeout, $location) {
    
    if ($sessionStorage.id != null) {

        $log.info('Overview Controller loaded!');

        var leaf = Leaflet;
        var map = {};
        var mapBounds = [];

        var init = function () {
            map = leaf.showmap('map',[39.5203614, 22.6116068],7,true);
            angular.forEach($scope.areas, function(value, key){
                var temp = '<div class="text-danger">'+value.title+'<br/>'+value.description+'<br/></div>';

                value.marker = leaf.addmarker(map,value.center,temp,2);
                value.marker.on('click',function(){
                    $scope.openAreaSettings(value.id);
                });
                mapBounds.push(value.center);
            });
            if (mapBounds.length > 1) {leaf.fitLayers(map,mapBounds);} else {leaf.zoom(map,15,mapBounds[0])}

            $scope.$emit('refresh');
        }

        if ($scope.status.dataReady) {init();}
        $scope.$on('dataReady', function(e) {init();});
    }
});