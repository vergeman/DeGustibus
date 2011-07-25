/*
Cluster javascript methods for client side
access

*/
function Item (Fid, Fname, Fdescription, Fprice, Rname, Rcuisines, Rdescription, Rlatitude, Rlongitude) {
    this.Fid = Fid;
    this.Fname = Fname;
    this.Fdescription = Fdescription;
    this.Fprice = Fprice;
    this.Rname = Rname;
    this.Rcuisines = Rcuisines;
    this.Rdescription = Rdescription;
    this.Rlatitude = Rlatitude;
    this.Rlongitude = Rlongitude; 
}



//User globas necessary to retrieve data
//will return "undefined"
var client = "PhpClient.php";

var S = new Array();
var L = new Array();
var C = Math.floor(Math.random()*100);
var num_results = 3;
var Items = new Array();

var captions = new Array();

var search = new Array();

var saved = new Array();


function Search(terms) {

    var result;
    search = new Array();

    $.ajax({
        url: "Search.php",
        type: 'POST',
        data: $.param({terms: terms}),
        dataType: 'text',
        error: function(xhr, textStatus, errorThrown) {
            //alert("Error accessing the server");
	    //NO RESULTS CASE
	    //var html = "<p> No Results </p>";
	    
        },
        success: function(data, textStatus) {
            //alert(data);
            var obj = jQuery.parseJSON(data);

            $.each (obj, function(i, result) {

                //alert(result["name"]);  //gives three names
                search[i] = new Item(result["Fid"], result["Fname"], result["Fdescription"], 
				     result["Fprice"], result["Rname"], result["Rcuisines"], 
				     result["Rdescription"], result["Rlatitude"], result["Rlongitude"]);

            });  //end each loop


        },
        complete: function(xhr) {
            //CALLBACK HERE on Completion of AJAX Request
	    if (search.length >0) {
		updateResults(search);
	    }
	    else {
		$('.search_results_table tbody').html("No Results");	
	    }
        }
    });
    //end ajax
}

//Output Search Results
function updateResults(search) {

    var html = "";

    $.each(search, function(i, result) {

	//build table	
	html+="<tr>"
	html+="<td>" + result.Fname + "</td>";
	html+="<td>" + result.Fdescription + "</td>";
	html+="<td>" + result.Fprice + "</td>";
	html+="<td>" + result.Rname + "</td>";
	html+="<td>" + result.Rcuisines + "</td>";
	html+="</tr>"

    });

    $('.search_results_table tbody').html(html);
}



//AJAX request for Cluster food items
function getItems(S, L, C, num_results) {

    var result;

    $.ajax({
	url: client,
	type: 'POST',
	data: $.param({S: S, L: L, C: C, num_results: num_results}), 
	dataType: 'text',
	async: false,  //not the best but we'll use it because we prefer all results no stickiness
	timeout: 5000,
	error: function(xhr, textStatus, errorThrown) {
	    //alert(textStatus);
	    alert("error");
	},
	success: function(data, textStatus) {
	    //alert(data);
	    var obj = jQuery.parseJSON(data);

	    $.each (obj, function(i, result) {
		
		//alert(result["name"]);  //gives three names
		Items[i] = new Item(result["Fid"], result["Fname"], result["Fdescription"], 
				    result["Fprice"], result["Rname"], result["Rcuisines"], 
				    result["Rdescription"], result["Rlatitude"], result["Rlongitude"]);
		
		S.push($.trim( result["Fid"] ) ); //add to S - seen dishes

	    });  //end each loop

	},
	complete: function(xhr) {
	    //CALLBACK HERE on Completion of AJAX Request
	    updateClusterItem(Items);

	}
    });
    //end ajax
}



function updateClusterItem(Items) {    
    //clear previous g_map locations
    clearMap("slider");

    var html = "";
    //Items[0].Fid;
    $.each(Items, function(i, result) {
	//ITEM CONTAINER
	html += "<div class = \"item\" >";

	//TITLE sub container
	html += "<div class = \"title\">";
	html += "<h3>";
	html += result.Fname;
	html += "</h3>";
	html += "</div>";
	
	//INFO sub container
	html += "<div class = \"item_info\">";
	html += "Price: $" + result.Fprice + "<br>";
	html += "<p>";
	html += result.Fdescription + "<br>";
	html += "</p>";

	//RESTAURANT INFO
	html += "<div class = \"restaurant_info\">";
	html += "<h3>";
	html += result.Rname;
	html += "</h3>";
	html += "<i>";
	html += "Cuisines: ";
	html += "</i>";
	html += result.Rcuisines + "<br>";

	html += "<p>";
	html += result.Rdescription;
	html += "</p>";

	html += "</div>";
	html += "</div>";
	

	//SAVE button
	html += "<div class = \"similar\" id=" + result.Fid + ">";
	html += "<button class = \"item_button\">similar</button>";
	html += "</div>";

	//LIKE button
	html += "<div class = \"save\" id=" + result.Fid + ">";
	html += "<button class = \"item_button\">save</button>";
	html += "</div>";
	//end item
	html += "</div>";

	//spacer
	html += "<div class = \"item_space\">";	
	html += "</div>";

	//UPDATE MAP
	var latlng = new google.maps.LatLng(result.Rlatitude, result.Rlongitude);

	addMap(latlng, result.Fname, result.Rname, "slider");
    });
    
    //write html
    $('#cluster_item').html(html);

    //$(".item_button").button({icons: {primary: "ui-icon-triangle-1-e"}});
    $(".item_button").button();

    //SAVE HOOKS
    $('.save').hover(function() {
        $(this).css("color", "yellow");
    }, function() {
        $(this).css("color", "white");
    });

    //SIMILAR HOOKS
    $('.similar').hover(function() {
        $(this).css("color", "yellow");
    }, function() {
        $(this).css("color", "white");
    });

    //SAVE UPDATE
    $('.save').click(function() {
	id = $(this).attr("id");

	//add to Liked list if its different than others
	test = false;

        if( $('.caption_table tr').length > 0) {
            //prevent dupliactes
            $.each ( $('.caption_table tr'), function() {
                if($(this).attr('id') == id) {
                    test = true;
		}
            });
        }

        if (test == false) {
	    //add to saved array
            saved.push( $(this).attr("id"));

	    //update markup
            update_cluster_caption( $(this).attr("id") );
        }

    });


    //SIMILAR UPDATE
    $('.similar').click(function() {
        id = $(this).attr("id");

        //add to saved list if its different than others
        test = false;

        $.each(L, function(i, element) {
            if(element == id) {
                test = true;
            }
        });

        if (test == false) {
            L.push( $(this).attr("id"));
            //S= [];

            update_cluster_similar( $(this).attr("id") );
        }

    });



}

//for saved items
function update_cluster_caption(id) {
    var html = "";

    //find item
    $.each(Items, function(i, item) {

        //add item
        if(id == item.Fid) {

            //add list text
            html += "<tr id = " + item.Fid + ">";
            html += "<td id = r_" + item.Fid + "> X " + item.Rname +" </td>";
            html += "<td id = " + item.Fid + "> " + item.Fname + "</td>";
            html += "</tr>";
            $('.caption_table').append(html);	    

	    //update map
	    var latlng = new google.maps.LatLng(item.Rlatitude, item.Rlongitude);
	    addMap(latlng, item.Fname, item.Rname, "search");

            //Button remove capacity (goes in td 1)
            $('.caption_table tr').hover(function() {
                $(this).css("color", "red");
            }, function() {
                $(this).css("color", "white");
            });


           //register remove ability
            $('.caption_table tr').click(function () {
                var id = $(this).attr("id");

		removeMarker($(this).children().next().html(), "search" );
                //remove from saved preferences		
                $.each(saved, function(i, element) {
                    if(element == id) {
                        saved.splice(i, 1);
			//remove from map
                    }
                });

                //remove markup
                $(this).remove();


                if(saved.length == 0 && $('#cluster_caption').is(':visible') ) {
                    $('#cluster_caption').slideUp('slow');
                }

            });

            if(saved.length > 0 && $('#cluster_caption').is(':hidden') ) {
                $('#cluster_caption').slideDown('slow');
            }

        }
    });

}


//for similar items
function update_cluster_similar(id) {
    var html = "";

    //find liked item
    $.each(Items, function(i, item) {

	//add item
	if(id == item.Fid) {
	    
	    //add list text
	    html += "<tr id = " + item.Fid + ">";
	    html += "<td id = r_" + item.Fid + ">X</td>";
	    html += "<td id = " + item.Fid + "> " + item.Fname + "</td>";
	    html += "</tr>";
	    $('.similar_table').append(html);

	    //Button remove capacity (goes in td 1)
	    $('.similar_table tr').hover(function() {
		$(this).css("color", "red");
	    }, function() {
		$(this).css("color", "white");
	    });

            //register remove ability
            $('.similar_table tr').click(function () {
                var id = $(this).attr("id");

                $.each(L, function(i, element) {
		    if(element == id) {
			L.splice(i, 1);
		    }
		});

		//remove markup
                $(this).remove();                

                if(L.length == 0 && $('#cluster_similar').is(':visible') ) {
                    $('#cluster_similar').slideUp('slow');
                }
            });

            if(L.length > 0 && $('#cluster_similar').is(':hidden') ) {
                $('#cluster_similar').slideDown('slow');
            }
            
	}//endif

    });//end each
    
}






//akin to a "main"
$(document).ready(function() {

    //need to fill hooks/ register events so we need a list of DOM objects
    //$('#cluster').corner();

    //===HOOOKS==
    //$('#button_next').button({icons: {primary: "ui-icon-triangle-1-e"}});

    initialize_map();

    //CLUSTER SLIDER
    $('#cluster_button_next').hover(function() {
	$(this).css("border-color", "transparent transparent transparent yellow");
    }, function() {
	$(this).css("border-color", "transparent transparent transparent white");
    });


    $('#cluster_button_next').click(function () {
	C = C + 3;  //increment clustser
	//alert(C);
	getItems(S, L, C, num_results);
    });

    //hide similar items div
    $('#cluster_caption').hide();
    $('#cluster_similar').hide();

    //hook search button
    $('#search_button').button();
/*
    $('#search_button').click(function() {

	var terms = $('#search_form_text').val();
	alert(terms);
	Search(terms);
    });
*/

    $('#search_form').submit( function(e) {
	e.preventDefault();
	var terms = $('#search_form_text').val();
	Search(terms);
    });


    //==BOOT
    //call getItems
    getItems(S, L, C, num_results);




});