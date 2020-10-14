'use strict';

/**
 * @ngdoc function
 * @name cityZenLights.controller:MarkersCtrl
 * @description
 * # MarkersCtrl
 * Controller of cityZenLights
 */
angular.module('cityZenLights')
.controller('MarkersCtrl', function($scope, $state, $log, Data, $timeout, Leaflet, $uibModalInstance, $filter) {
  
  $log.info('Markers Controller loaded!');

  var leaf = Leaflet;
  var map = {};
  var bounds = [];

  $scope.areas = Data.areas();
  $scope.selectedArea = $filter('filter')($scope.areas, {id: $scope.$resolve.area}, true)[0];
  $scope.lightTypes = Data.lightTypes();

  $scope.data = {
    needSave: false
  };

  $scope.saveAllLights = function () {
    
    var tempLights = _.map($scope.selectedArea.lights, function (item) {return {id:item.id,lat:item.position[0],lng:item.position[1]};});
    Data.saveMultipleLights(tempLights).then(function (res) {
      if(res){
        $uibModalInstance.close();
      }else{
        alert("Η αποθήκευση δεν έγινε!");
      }
    }, function (err) {
      $log.error(err);
      alert("Η αποθήκευση δεν έγινε!");
    })
  }

  $timeout(function () {
      map = leaf.showmap('dragMap',[39.5203614, 22.6116068],7,true);
      angular.forEach($scope.selectedArea.lights, function(value, key){
          var type = $filter('filter')($scope.lightTypes, {id: value.type}, true)[0];
          var temp = '<div class="text-danger">Ιστός '+value.id+'<br/>Τύπος: '+type.title+'<br/>Λαμπτήρες: '+value.lamps.length+'<br/>';

          var marker = leaf.addDraggableMarker(map,value.position,temp,1);
          marker.on('dragend',function(e){
            value.position = [String(e.target.getLatLng().lat),String(e.target.getLatLng().lng)];
            bounds.push(value.position);
            leaf.fitLayers(map,bounds);
            $scope.data.needSave = true;
            $scope.$apply();
          });
          bounds.push(value.position);
      });
      leaf.fitLayers(map,bounds);
  },500);

  $scope.ok = function () {

    $uibModalInstance.close();
  };

  $scope.cancel = function () {

    $uibModalInstance.dismiss('cancel');
  };
});