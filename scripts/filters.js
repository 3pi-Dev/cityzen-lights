angular.module('cityZenLights').filter("fDate", function($filter) {

	return function(input, format) {
		var d = new Date(input);
		d = $filter('date')(d, format);
		return d;
	};
});