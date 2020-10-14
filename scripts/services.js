'use strict';

/**
 * services
 */

angular.module('cityZenLights').factory('Server', function ($http, $log, $q) {

    var serveDomain = 'api/';

    return {

        req: function (method, params) {
        	
            if (method == 'GET') {
                return $http({
                    method: method,
                    url: serveDomain,
                    params: params
                }).then(
                    function(response) {
                        return response.data;
                    },
                    function(error) {
                        return $q.reject(error);
                    }
                );
            } else {
                return $http({
                    method: method,
                    url: serveDomain,
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded'
                    },
                    transformRequest: function(obj) {
                        var str = [];
                        for(var p in obj)
                        str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
                        return str.join("&");
                    },
                    data: params
                }).then(
                    function(response) {
                        return response.data;
                    },
                    function(error) {
                        return $q.reject(error);
                    }
                );
            }
        }
    };
});

angular.module('cityZenLights').factory('AuthService',

    function (Server, $state, $sessionStorage, Log) {

        var username = '';

        return {
            login:function (user, pass) {
                
                var login = Server.req('GET', {act:'login',username:user,password:pass});
                return login;
            },
            logout:function () {

                Log.add('logout action');
                $sessionStorage.$reset();
                Server.req('GET', {act:'logout'}).then(function (res) {
                    $state.transitionTo('login', null, {reload: true});
                }, function (err) {
                    $log.error(err);
                    $state.transitionTo('login', null, {reload: true});
                })
            }
        };
    }

);

angular.module('cityZenLights').factory('Data', function( Server, $log, $http, $q, $filter, $sessionStorage){

    var data = {};
    data.areas = [];
    data.users = [];
    data.reports = [
        {id: 0,title: 'Ωριαία κατανάλωση'},
        {id: 1,title: 'Ημερήσια κατανάλωση'},
        {id: 2,title: 'Μηνιαία κατανάλωση'},
        {id: 3,title: 'Hμερήσια μέση ισχύς'},
        {id: 4,title: 'Πίνακας συμβάντων'}
    ];
    data.lightTypes = [];
    data.lampTypes = [];

	return {

        getAreas: function () {
            
            return Server.req('GET', {act:'initData'});
        },

        areas: function () {
            
            return data.areas;
        },

        lightTypes: function () {
            
            return data.lightTypes;
        },

        lampTypes: function () {
            
            return data.lampTypes;
        },

        getStatus: function () {
            
            return Server.req('GET', {act:'getCurrentState'});
        },

        setStatus: function (plr) {
            
            return Server.req('GET', {
                act:'changeState',
                pil_id:plr.id,
                dateActive:$filter('date')(new Date(), 'yyyy-MM-dd HH:mm:ss'),
                stateType:1,
                status:(plr.status?1:2)
            });
        },

        getReports: function () {
            
            var deferred = $q.defer();
            deferred.resolve(data.reports);
            return deferred.promise;
        },

        reportData: function (rep,params) {
            
            switch(rep.id){
                case 0:
                    return Server.req('GET', {
                        act: 'getDailyUsage',
                        pil_id: params.area,
                        date: $filter('date')(params.reportFrom, 'yyyy-MM-dd')
                    });
                    break;
                case 1:
                    params.reportFrom.setDate(1);
                    params.reportTo = new Date(params.reportFrom.getFullYear(),params.reportFrom.getMonth()+1,0);
                    return Server.req('GET', {
                        act: 'getWeeklyUsage',
                        pil_id: params.area,
                        dateFrom: $filter('date')(params.reportFrom, 'yyyy-MM-dd'),
                        dateTo: $filter('date')(params.reportTo, 'yyyy-MM-dd')
                    });
                    break;
                case 2:
                    var from = new Date(params.reportFrom.getFullYear(),0,1);
                    var to = new Date(params.reportFrom.getFullYear(),12,0);
                    return Server.req('GET', {
                        act: 'getMonthlyUsage',
                        pil_id: params.area,
                        dateFrom: $filter('date')(from, 'yyyy-MM-dd'),
                        dateTo: $filter('date')(to, 'yyyy-MM-dd')
                    });
                    break;
                case 3:
                    return Server.req('GET', {
                        act: 'getDailyPower',
                        pil_id: params.area,
                        dateFrom: $filter('date')(params.reportFrom, 'yyyy-MM-dd'),
                        dateTo: $filter('date')(params.reportTo, 'yyyy-MM-dd')
                    });
                    break;
                case 4:
                    return Server.req('GET', {
                        act: 'getPillarEvents',
                        pil_id: params.area,
                        dateFrom: $filter('date')(params.reportFrom, 'yyyy-MM-dd HH:mm'),
                        dateTo: $filter('date')(params.reportTo, 'yyyy-MM-dd HH:mm')
                    });
                    break;
                default:
                    var deferred = $q.defer();
                    deferred.resolve('No Data');
                    return deferred.promise;
                    break;
            }
        },

        todayEvents: function (id,obj) {
            
            return Server.req('GET', {
                act: 'getPillarEvents',
                pil_id: obj.area,
                dateFrom: $filter('date')(obj.from, 'yyyy-MM-dd HH:mm'),
                dateTo: $filter('date')(obj.to, 'yyyy-MM-dd HH:mm')
            });
        },

        getTypes: function () {
            
            return Server.req('GET', {act:'getPillarAndLightTypes'});
        },

        setTypes: function (lgts,lmps) {
            
            data.lightTypes = lgts;
            data.lampTypes = lmps;
        },

        saveLight: function (lgt) {
            
            var lights = '';
            angular.forEach(lgt.lamps, function(l, k){
                lights += l.id + ',' + l.power + ',' + l.type + '|';
            });
            return Server.req('GET', {
                act:'updatePoleAndLights',
                pol_id:lgt.id,
                pole_type:lgt.type,
                pole_height:lgt.height,
                lat:lgt.position[0],
                lng:lgt.position[1],
                lights:lights
            });
        },

        saveMultipleLights: function (lgts) {
            
            var lights = '';
            angular.forEach(lgts, function(l, k){
                lights += l.id + ',' + l.lat + ',' + l.lng + '|';
            });
            return Server.req('GET', {
                act:'updateMultiplePoles',
                poles: lights
            });
        },

        getLightImg: function (id) {
            
            return Server.req('GET', {act:'getLatestPollImage',pol_id:id});
        },

        getDailyLoss: function (id) {
            
            return Server.req('GET', {
                act:'getApoleia',
                pillarID:id
            });
        },

        saveAlarm: function (plr,alarm) {
            
            return Server.req('GET', {
                act:'insertAlert',
                pillarID : plr,
                enabled : alarm.status==true?1:0,
                datefrom : $filter('date')(alarm.datefrom, 'yyyy-MM-dd'),
                dateto : $filter('date')(alarm.dateto, 'yyyy-MM-dd'),
                timefrom : $filter('date')(alarm.timefrom, 'HH:mm'),
                timeto : $filter('date')(alarm.timeto, 'HH:mm'),
                condition : alarm.opr==true?1:0,
                pvalue : alarm.watt,
                sms : alarm.phone,
                email : alarm.mail
            });
        },

        updateAlarm: function (alarm) {
            
            return Server.req('GET', {
                act:'updateAlert',
                alertID : alarm.id,
                enabled : alarm.status==true?1:0,
                datefrom : $filter('date')(alarm.datefrom, 'yyyy-MM-dd'),
                dateto : $filter('date')(alarm.dateto, 'yyyy-MM-dd'),
                timefrom : $filter('date')(alarm.timefrom, 'HH:mm'),
                timeto : $filter('date')(alarm.timeto, 'HH:mm'),
                condition : alarm.opr==true?1:0,
                pvalue : alarm.watt,
                sms : alarm.phone,
                email : alarm.mail
            });
        },

        deleteAlarm: function (id) {
            
            return Server.req('GET', {
                act:'deleteAlert',
                alertID: id
            });
        },

		getAlarms: function (id) {
			
			return Server.req('GET', {
                act:'getAlerts',
                pillarID:id
            });
		},

        getUsers: function () {
            
            return Server.req('GET', {act:'getUsers'});
        },

        users: function () {
            
            return data.users;
        },

        saveUser: function (usr) {
            
            return Server.req('GET', {
                act:'insertUser',
                username:usr.username,
                password:usr.password,
                type:usr.type,
                email:usr.email,
                phone:usr.phone,
                name:usr.name
            });
        },

        updateUser: function (usr) {
            
            return Server.req('GET', {
                act:'updateUser',
                id:usr.id,
                username:usr.username,
                password:usr.password,
                type:usr.type,
                email:usr.email,
                phone:usr.phone,
                name:usr.name
            });
        },

        deleteUser: function (id) {
            
            return Server.req('GET', {
                act:'deleteUser',
                id:id
            });
        }
	};
})


angular.module('cityZenLights').factory('Log',

    function (Server, $sessionStorage) {

        return {
            get: function (id) {

                return Server.req('GET', {act:'getLogs',user:id});
            },

            add: function (item) {
                
                Server.req('GET', {
                    act:'insertLog',
                    user:$sessionStorage.id,
                    description:item
                });
            }
        }
    }
);


angular.module('cityZenLights').factory('preventTemplateCache', function() {
    var version = '19.05.08';
    return {
        'request': function(config) {
            if (config.url.indexOf('views') !== -1) {
                config.url = config.url + '?v=' + version;
            }
            return config;
        }
    }
})
.config(function($httpProvider) {
    $httpProvider.interceptors.push('preventTemplateCache');
});