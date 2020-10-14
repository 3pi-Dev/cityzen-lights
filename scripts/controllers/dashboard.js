'use strict';

/**
 * @ngdoc function
 * @name cityZenLights.controller:MainCtrl
 * @description
 * # MainCtrl
 * Controller of cityZenLights
 */
angular.module('cityZenLights')
.controller('DashboardCtrl', function($scope, $state, $uibModal, $location, Leaflet, $log, $sessionStorage, Data, $filter, $sce, $timeout, AuthService) {

    if ($sessionStorage.id != null) {

        $scope.$state = $state;
        $scope.user = {
            id: $sessionStorage.id,
            name: $sessionStorage.name,
            type: $sessionStorage.type
        };
        var leaf = Leaflet;
        $scope.status = {
            dataReady: false,
            open1: false,
            open2: false
        };
        $scope.areas = Data.areas();
        $scope.lightTypes = Data.lightTypes();
        $scope.lampTypes = Data.lampTypes();
        $scope.reports = [];

        moment.locale('el');

        $scope.logout = function () {
            AuthService.logout();
        }

        $scope.openAreaSettings = function (id) {

            var modalInstance = $uibModal.open({
                animation: true,
                size: 'lg',
                templateUrl: 'settings1.html',
                controller: 'SettingsCtrl',
                resolve: {
                    area: function () {
                        return id;
                    }
                }
            });
        }

        $scope.editMarkers = function (id) {
            
            var modalInstance = $uibModal.open({
                animation: true,
                size: 'lg',
                templateUrl: 'settings3.html',
                controller: 'MarkersCtrl',
                resolve: {
                    area: function () {
                        return id;
                    }
                }
            });
        }

        var refresh = function () {
            
            Data.getStatus().then(function (res) {
                $log.warn('refreshing..');
                angular.forEach(res, function(plr, pkey){
                    var temPillar = $filter('filter')($scope.areas, {id: plr.pil_id}, true)[0];
                    var tmp = parseFloat(plr.Fasi1_watt) + parseFloat(plr.Fasi2_watt) + parseFloat(plr.Fasi3_watt);
                    temPillar.updatedAt = new Date(plr.E_DATE);
                    temPillar.power = tmp;

                    temPillar.powerFlow.push(tmp);
                    temPillar.powerLabels.push(plr.E_DATE.split(" ")[1]);
                    if (temPillar.powerFlow.length>10) {
                        temPillar.powerFlow.shift();
                        temPillar.powerLabels.shift();
                    }

                    temPillar.consumption = parseFloat(plr.watt_hours);
                    if (temPillar.power > 100) {
                        leaf.setIcon(temPillar.marker,0);
                        temPillar.status = true;
                    }else{
                        leaf.setIcon(temPillar.marker,2);
                        temPillar.status = false;
                    }
                });
                
                $timeout(function () {refresh()},10000);
            }, function (err) {
                $log.error(err);
            })
        }

        Data.getTypes().then(function (res) {
            $scope.lightTypes = _.map(res.poleTypes, function(item,key){return {id: item.POLT_ID,title: item.POLT_DESCR};}),
            $scope.lampTypes = _.map(res.lightTypes, function(item,key){return {id: item.LIGT_ID,title: item.LIGT_DESCR};}),
            Data.setTypes($scope.lightTypes,$scope.lampTypes);

            Data.getAreas().then(function (ars) {
                angular.forEach(ars, function(plr, pk){
                    var pillar = {
                        id: plr.PIL_ID,
                        title: plr.PIL_DESCR,
                        description: 'περιγραφή ομάδας',
                        ip: plr.DEV_IP,
                        power: 0,
                        consumption: 0,
                        maxPower: (plr.TOTAL_WATT?plr.TOTAL_WATT:0),
                        status: false,
                        program: 0,
                        from: '17:00',
                        to: '06:00',
                        on: 0,
                        off: 0,
                        lux: 400,
                        center: [plr.PIL_LAT,plr.PIL_LNG],
                        lights: [],
                        powerFlow: [],
                        powerLabels: [],
                        alarms: _.map(plr.alerts, function(item,key){
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
                        }),
                        updatedAt: new Date()
                    }
                    angular.forEach(plr.poles, function(lgt, lk){
                        var pole = {
                            id: lgt.POL_ID,
                            type: lgt.POLT_ID,
                            height: parseFloat(lgt.POL_HEIGHT),
                            lamps: _.map(lgt.lights, function(item,key){return {id: item.POLL_ID,type: item.LIGT_ID,power: parseFloat(item.POLL_WATT)};}),
                            position: [lgt.POL_LAT,lgt.POL_LNG]
                        }
                        pillar.lights.push(pole);
                    });
                    $scope.areas.push(pillar);
                });

                $scope.status.dataReady = true;
                $scope.$broadcast('dataReady');

                Data.getReports().then(function (reps) {
                    $scope.reports = reps;
                }, function (repsEr) {
                    $log.error(repsEr);
                })
            }, function (arsEr) {
                $log.error(arsEr);
            })

        }, function (err) {
            $log.error(err);
        })
    }else{
        $location.path('login');
    }

    $scope.$on('refresh', function(event) {refresh();});

    Date.prototype.addDays = function(days) {
        this.setDate(this.getDate() + parseInt(days));
        return this;
    };

    Date.prototype.addHours = function(hours) {
        this.setHours(this.getHours() + parseInt(hours));
        return this;
    };
});