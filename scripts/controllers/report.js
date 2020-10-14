'use strict';

/**
 * @ngdoc function
 * @name cityZenLights.controller:ReportCtrl
 * @description
 * # ReportCtrl
 * Controller of cityZenLights
 */
angular.module('cityZenLights')
.controller('ReportCtrl', function($scope, $state, $stateParams, $location, $log, $filter, $timeout, Data) {

    if ($stateParams.reportID != null) {

        $log.info('Reports Controller loaded!');

        var report = $stateParams.reportID;
        $scope.currentReport = $filter('filter')($scope.reports, {id: $stateParams.reportID}, true)[0];

        $scope.params = {
            reportFrom: new Date(),
            reportTo: new Date(),
            area: 0
        }

        $scope.show = {
            spin: false,
            msg: false,
            data: false
        }

        $scope.monthOpts = {
            minMode: 'month',
            datepickerMode: 'year'
        }

        $scope.yearOpts = {
            minMode: 'year',
            datepickerMode: 'year'
        }


        $scope.showReport = function () {

            $scope.show.spin = true;
            $scope.show.msg = false;
            $scope.show.data = false;

            $scope.labels = [];
            $scope.data = [[],[]];
            $scope.data1 = [];
            $scope.type = 'line';
            $scope.total = 0;
            $scope.options = {
                title: {
                    display: true,
                    text: $scope.currentReport.title
                },
                legend: {
                    display: true
                },
                scales: {
                    yAxes: [{
                        scaleLabel: {
                            display: true,
                            labelString: $scope.currentReport.id==3?'Watt':'kWh'
                        }
                    }],
                    xAxes: [{
                        scaleLabel: {
                            display: true,
                            labelString: 'time'
                        }
                    }]
                }
            }

            Data.reportData($scope.currentReport,$scope.params).then(function (res) {

                switch ($scope.currentReport.id){
                    case 0:
                        var today = new Date($scope.params.reportFrom);
                        var yesterday = new Date($scope.params.reportFrom);
                        yesterday.addDays(-1);
                        $scope.series = [$filter('date')(yesterday, 'dd/MM/yyyy'),$filter('date')(today, 'dd/MM/yyyy')];
                        break;
                    case 3:
                        $scope.series = ['Μέση ισχύς','Μέγιστη ισχύς'];
                        var tmpArea = $filter('filter')($scope.areas, {id: $scope.params.area}, true)[0];
                        break;
                    default:
                        $scope.series = ['Μέση κατανάλωση'];
                        $scope.options.legend.display = false;
                        break;
                }

                if (_.isEmpty(res.values)) {
                    $timeout(function () {$scope.show.spin = false;$scope.show.msg = true;},1000)
                } else {
                    angular.forEach(res.values, function(value, key){
                        switch($scope.currentReport.id){
                            case 0:
                                $scope.labels.push(value.TimeSep);
                                if (key<12) {
                                    $scope.data[0].push(parseFloat(value.Kwh/1000));
                                    $scope.data[1].push(null);
                                }
                                if (key==12) {
                                    $scope.data[0].push(parseFloat(value.Kwh/1000));
                                    $scope.data[1].push(parseFloat(value.Kwh/1000));
                                }
                                if (key>12) {
                                    $scope.data[0].push(null);
                                    $scope.data[1].push(parseFloat(value.Kwh/1000));
                                }
                                break;
                            case 1:
                                var tmp = [key.split('-')[2],[key.split('-')[1]]].join("/");
                                $scope.labels.push(tmp);
                                if (value[0].length!=0) {
                                    $scope.data[0].push(parseFloat(value[0].Kwh/1000));
                                } else {
                                    $scope.data[0].push(0);
                                }
                                break;
                            case 2:
                                var tmp = [key.split('-')[1],[key.split('-')[0]]].join("/");
                                $scope.labels.push(tmp);
                                if (value[0].length!=0) {$scope.data[0].push(parseFloat(value[0].Kwh/1000));} else {$scope.data[0].push(0);}
                                break;
                            case 3:
                                var tmp = key.split('-').reverse().join("/");
                                $scope.labels.push(tmp);
                                if (value) {$scope.data[0].push(value);$scope.data[1].push(tmpArea.maxPower);} else {$scope.data[0].push(0);$scope.data[1].push(tmpArea.maxPower);}
                                break;
                            case 4:
                                $scope.data1.push([value.pile_date,value.pile_type,value.pile_status]);
                                break;
                            default:
                                break;
                        }
                    });
                    $scope.total = res.total/1000;
                    $timeout(function () {$scope.show.spin = false;$scope.show.data = true;},1000)
                }
            }, function (err) {
                $log.error(err);
            })
        }

        $scope.toggle = function () {
          $scope.type = $scope.type === 'line' ? 'bar' : 'line' ;
        };
    } else {
        $location.path('dashboard');
    }
});