/*
javascript for google maps interface

*/

var g_map;
var slider_items = [];
var search_items = [];

var slider_icon = "http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=|FF0000|000000";

var search_icon = "http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=|0000FF|000000";



function initialize_map() {
    //center of map
    var latlng = new google.maps.LatLng(40.807569,-73.963884);

    var myOptions = {
	zoom: 13,
	center: latlng,
	mapTypeId: google.maps.MapTypeId.ROADMAP
    }
  
    //build map
    g_map = new google.maps.Map(document.getElementById("map_canvas"),
				  myOptions);


}


//removes based on item text (name)
function removeMarker(title, array) {

    if (array == "slider") {
	for (i in slider_items) {
	    if($.trim(slider_items[i].title) == $.trim(title)) {
		slider_items[i].setMap(null);
		slider_items.splice(i, 1);
	    }
	}

    }
    else {
	for (i in search_items) {
	    if( $.trim(search_items[i].title) == $.trim(title) ) {
		search_items[i].setMap(null);
		search_items.splice(i, 1);
	    }
	}
    }
}

//adds item
function addMap(location, text, restaurant, array) {
    var marker = new google.maps.Marker({
	position: location,
	map: g_map,
	title: text,
    });

    var string = "<font color=\"#000001\">" + text;
    string += "<br>" + restaurant + "</font>";

    var infowindow = new google.maps.InfoWindow({
	content: string
    });

    google.maps.event.addListener(marker, 'click', function() {
	infowindow.open(g_map, marker);
    });

    if (array == "search") {
	marker.icon = search_icon;
	search_items.push(marker);
    }
    else {
	marker.icon = slider_icon;
	slider_items.push(marker);
    }
}


function clearMap(array) {
    if(array == "search") {
	for (i in search_items) {
	    search_items[i].setMap(null);
	}
	search_items.length=0;

    }
    else {
	for (i in slider_items) {
	    slider_items[i].setMap(null);
	}
	slider_items.length=0;
    }

}


$(document).ready(function() {
    

/*
    var my_spot = new google.maps.LatLng(40.087569, -73.963884);
    var marker = new google.maps.Marker({
	position: my_spot, map: g_map, title:"Hello World!"});
*/
  //  alert(marker);

});


