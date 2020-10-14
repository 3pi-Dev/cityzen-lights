'use strict';

/**
 * Angular service for Leaflet
 * OpenStreet Maps Functions
 * by Andreas Mpachtsevanos
 */
angular.module('cityZenLights').factory('Leaflet', function($log){

    var lightIcon = [];
    lightIcon[0] = L.icon({
        iconUrl: 'images/pillaron.png',
        iconSize:     [54, 60],
        iconAnchor:   [18, 34],
        tooltipAnchor: [20, 0]
    });
    lightIcon[1] = L.icon({
        iconUrl: 'images/light.png',
        iconSize:     [42, 50],
        iconAnchor:   [10, 38],
        tooltipAnchor: [20, -10]
    });
    lightIcon[2] = L.icon({
        iconUrl: 'images/pillaroff.png',
        iconSize:     [54, 60],
        iconAnchor:   [18, 34],
        tooltipAnchor: [20, 0]
    });
    lightIcon[3] = new L.Icon.Default();

    return {

        /**
         * initializes a new leaflet map obj
         * @param  {int}    id      element for map
         * @param  {latlng} center  coordinates to center map
         * @param  {bool}   drag    enable/disable map dragging
         * @param  {bool}   zoom    en/disable map zoom control
         */
        showmap : function(id,center,zoom,drag){

            var OpenStreetMap_Mapnik = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {maxZoom: 19,attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'});
            var OpenStreetMap_HOT = L.tileLayer('http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png', {maxZoom: 19,attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>, <a href="http://hot.openstreetmap.org/" target="_blank"> Humanitarian Team</a>'});
            var OpenMapSurfer_Roads = L.tileLayer('http://korona.geog.uni-heidelberg.de/tiles/roads/x={x}&y={y}&z={z}', {maxZoom: 20,attribution: '<a href="http://giscience.uni-hd.de/">GIScience@Heidelberg</a> &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'});
            var Esri_WorldStreetMap = L.tileLayer('http://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}', {attribution: '&copy; Esri 2012'});
            var CartoDB_Positron = L.tileLayer('http://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png', {attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> &dash; <a href="http://cartodb.com/attributions">CartoDB</a>',subdomains: 'abcd',maxZoom: 25});
            var Esri_WorldImagery = L.tileLayer('http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {attribution: '&copy; Esri'});
            
            return L.map(id, {
                center: center,
                zoom: zoom,
                scrollWheelZoom: true,
                dragging: drag,
                doubleClickZoom: true,
                trackResize: true,
                layers: CartoDB_Positron
            });

        },

        /**
         * adds a marker to the leaflet     map obj
         * @param  {obj}        map         map to add marker
         * @param  {array(int)} coords      marker position
         * @param  {text}       title       title shown on hover
         * @param  {int}        id          marker id attr
         * @param  {int}        iconimg     marker icon
         */
        addmarker : function(map,coords,title,icon,specs){

            if (specs) {
                return L.marker(coords,{
                    title: title,
                    riseOnHover: true,
                    icon: lightIcon[icon]
                }).bindPopup(specs).addTo(map);
            } else {
                return L.marker(coords,{
                    riseOnHover: true,
                    icon: lightIcon[icon]
                }).bindTooltip(title).addTo(map);
            }

        },
        addDraggableMarker : function(map,coords,title,icon){

            return L.marker(coords,{
                // title: title,
                riseOnHover: true,
                icon: lightIcon[icon],
                draggable: true
            }).bindTooltip(title).addTo(map);

        },

        /**
         * sets a new marker
         * @param  {obj} pos google maps LatLng obj
         * @return {obj}     google maps marker
         */
        setmarker : function (coords,title,id) {
            
            // return new google.maps.Marker({'position': pos});
            return new L.marker(coords,{
                title: title,
                riseOnHover: true,
                id: id
            }).bindLabel(title, { noHide: true, direction: 'auto' });

        },

        /**
         * adds a polyline in map
         * @param {[latlng]} coordinates coordinates
         */
        addPolyline : function(map,coordinates){

            return L.polyline(coordinates, {
                color: '#4d0000'
            }).addTo(map);

        },

        addPolygon : function (map,coordinates) {

            return L.polygon(coordinates, {
                color: '#000'
            }).addTo(map);

        },

        /**
         * removes any Layer from a Map
         * @param  {obj} map   the map obj
         * @param  {obj} layer the layer to remove
         */
        removeLayer : function (map,layer) {

            map.removeLayer(layer);

        },

        removeControl : function (map,ctrl) {

            map.removeControl(ctrl);

        },

        clearLayers : function (map) {
            map.eachLayer(function (layer) {
                if(!layer._url){
                    map.removeLayer(layer);
                }
            });
        },

        /**
         * zoom & pan curent map
         * @param  {obj} curmap map obj to zoom
         * @param  {int} num    zoom
         * @param  {obj} pos    LatLng obj
         */
        zoom : function(curmap,num,pos){

            curmap.setZoom(num);
            curmap.panTo(pos);

        },

        /**
         * creates bounds & gets the center
         * @return {obj} LatLng
         */
        centerOfPoints : function (points) {

            var x = L.bounds(points);
            return x.getCenter();

        },

        /**
         * get the center of an object
         * @param  {obj}        item geometry obj
         * @return {[obj]}      LatLng obj
         */
        getCenter : function (item) {

            return item.getCenter();

        },

        /**
         * fit layers to map "Leaflet fitBounds"
         * @param  {obj} map   the map obj
         * @param  {obj/array} bounds the bounds of layer/leyers
         */
        fitLayers : function (map,bounds) {

            map.fitBounds(bounds);

        },

        /**
         * reset map if already loaded
         * @param {obj} map    the map object
         * @param {array} center center, latlng
         * @param {int} zoom   zoom
         * @param {bool} drag   map draggable
         */
        setMap : function (map,center,zoom,drag) {
            
            map.setView(center,zoom,{
                scrollWheelZoom: false,
                dragging: drag,
                doubleClickZoom: false,
                trackResize: true
            });

        },

        /**
         * remove/destroy map object
         * @param  {[type]} map [description]
         * @return {[type]}     [description]
         */
        removeMap : function (map) {
            
            map.remove();

        },

        /**
         * change markers icon
         * @param {obj} marker marker object
         * @param {string} fo  font title
         * @param {string} co  font color
         * @param {string} sh  marker shape
         */
        setIcon : function (marker,icon) {
            
            // marker.setIcon(L.ExtraMarkers.icon({icon: fo,markerColor: co,shape: sh,prefix: 'fa'}));
            marker.setIcon(lightIcon[icon]);

        }

    };

});





