'use strict';

/**
 * @ngdoc function
 * @name cityZenLights.controller:SettingsCtrl
 * @description
 * # SettingsCtrl
 * Controller of cityZenLights
 */
angular.module('cityZenLights')
.controller('SettingsCtrl', function($scope, $state, $log, Data, $timeout, $uibModalInstance, $filter, $sessionStorage, $interval) {
  
  $log.info('Settings Controller loaded!');

  $scope.user = {
      id: $sessionStorage.id,
      name: $sessionStorage.name,
      type: $sessionStorage.type
  };

  $scope.areas = Data.areas();
  $scope.selectedArea = $filter('filter')($scope.areas, {id: $scope.$resolve.area}, true)[0];
  $scope.events = [];

  $scope.data = {
    needSave: false,
    tab: 0
  };

  var date = new Date();
  var temp1 = $scope.selectedArea.from.split(':');
  var temp2 = $scope.selectedArea.to.split(':');
  $scope.dateFrom = new Date(date.getFullYear(),date.getMonth(),date.getDate(),temp1[0],temp1[1]);
  $scope.dateTo = new Date(date.getFullYear(),date.getMonth(),date.getDate(),temp2[0],temp2[1]);
  $scope.dateOptions = {
      formatYear: 'yy',
      maxDate: new Date(2060, 5, 22),
      minDate: new Date(2005, 5, 22),
      startingDay: 1,
      showButtonBar: false
  };
  $scope.timeOptions = {
      readonlyInput: false,
      showMeridian: false
  };

  $scope.series = ['Ροή Ισχύος'];
  $scope.options = {
      animation: {
        duration: 0,
        easing: 'linear'
      },
      scales: {
          yAxes: [{
              ticks: {
                  beginAtZero:true
              }
          }]
      }
  }

  $scope.changeStatus = function () {
    
    Data.setStatus($scope.selectedArea).then(function (res) {
      $log.debug(res);
    }, function (err) {
      $log.error(err);
    })
  }

  $scope.detectLoss = function () {
    
    Data.getDailyLoss($scope.selectedArea.id).then(function (res) {
      $scope.dailyLoss = res[""];
    }, function (err) {
      $log.error(err);
    })
  }

  $scope.pillarEvents = function () {
    
    var start = new Date();
    var end = new Date();
    start.setHours(0, 0);
    end.setHours(23, 59);
    $scope.events = [];
    Data.todayEvents(4,{area:$scope.selectedArea.id,from:start,to:end}).then(function (res) {
      angular.forEach(res.values, function(value, key){
        $scope.events.push([value.pile_date,value.pile_type,value.pile_status]);
      });
    }, function (err) {
      $log.error(err);
    })
  }

  $scope.clearAlarm = function () {
    
    $scope.data.curentAlarm = {
      datefrom: new Date(),
      dateto: new Date(),
      timefrom: new Date(),
      timeto: new Date(),
      status: false,
      opr: false,
      phone: '',
      mail: ''
    }
  }
  $scope.clearAlarm();

  $scope.saveAlarm = function () {
    
    $log.debug($scope.data.curentAlarm);
    if ($scope.data.curentAlarm.id) {
      $log.debug('Update');
      Data.updateAlarm($scope.data.curentAlarm).then(function (lrm) {
        if(lrm.updated){
          $log.debug('saved!');
        }else{
          $log.debug('not saved!');
        }
      }, function (err) {
        $log.error(err);
      })
    } else {
      $log.debug('Save');
      Data.saveAlarm($scope.selectedArea.id,$scope.data.curentAlarm).then(function (lrm) {
        if(lrm.insertedID){
          $log.debug('saved!');
          $scope.data.curentAlarm.id = lrm.insertedID;
          $scope.data.curentAlarm.title = $filter('date')($scope.data.curentAlarm.datefrom, 'yyyy-MM-dd') + ' <-> ' + $filter('date')($scope.data.curentAlarm.dateto, 'yyyy-MM-dd');
          $scope.selectedArea.alarms.push($scope.data.curentAlarm);
        }else{
          $log.debug('not saved!');
        }
      }, function (lrmErr) {
        $log.error(lrmErr);
      })
    }
  }

  $scope.deleteAlarm = function () {
    
    Data.deleteAlarm($scope.data.curentAlarm.id).then(function (lrm) {
      if(lrm.deleted){
        $log.debug('deleted!');
        var index = $scope.selectedArea.alarms.indexOf($scope.data.curentAlarm);
        $scope.selectedArea.alarms.splice(index,1);
      }else{
        $log.debug('not deleted!');
      }
    }, function (lrmErr) {
      $log.error(lrmErr);
    })
  }

  $scope.refreshAlarms = function () {
    
    Data.getAlarms($scope.selectedArea.id).then(function (resAlr) {
      $scope.selectedArea.alarms = _.map(resAlr, function(item,key){
          var time1 = new Date();
          var time2 = new Date();
          time1.setHours(item.PILA_TIME_FROM.split(':')[0], item.PILA_TIME_FROM.split(':')[1], 0, 0);
          time2.setHours(item.PILA_TIME_TO.split(':')[0], item.PILA_TIME_TO.split(':')[1], 0, 0);
          return {
              id: key,
              title: item.PILA_DATE_FROM + ' <-> ' + item.PILA_DATE_TO,
              status: item.PILA_ENABLED=="0"?false:true,
              datefrom: new Date(item.PILA_DATE_FROM),
              dateto: new Date(item.PILA_DATE_TO),
              timefrom: time1,
              timeto: time2,
              mail: item.PILA_EMAIL,
              phone: item.PILA_SMS_PHONE,
              watt: parseInt(item.PILA_VALUE),
              opr: item.PILA_CONDITION=="0"?false:true
          };
      })
    }, function (errAlr) {
      $log.error(errAlr);
    })
  }

  $scope.ok = function () {

    $uibModalInstance.close();
  };

  $scope.cancel = function () {

    $uibModalInstance.dismiss('cancel');
  };

  $scope.needSaveTrue = function () {

    $scope.needSave = true;
  };
});