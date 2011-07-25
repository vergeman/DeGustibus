===CRAWLING STEPS===
Run these files sequentially - i.e. (step 1) would lbe to run get_restaurants.pl on the defined zipcode.xml file.  From those
results, you can (step 2) build_menu_queue.pl to get a list of menus to download and so forth.  Continue running each script.

The Data Prep Steps require having created database tables visible in the schema description.


get_restaurants.pl	#opens zipcode.xml and gets restaurant listings for that zip search, stored in ./restaurants
			#this will crawl delivery.com and foreach zipcode/addr pair in zipcodes.xml, downlad the corresonding list of restaurants available


build_menu_queue.pl 	#opens files in ./restaurants, and grabs restaurant id's per zipcode, populates into a zipcode file in ./menu_queue
			#these *.id files list the restaurants id's (for that filename zipcode) 	


get_menus.pl		#opens ./menu_queue files and polls website, downloads to ./menu/.  This actually calls delivery.com using curl
			#and grabs the menu.

===DATA PREP STEPS (DB)===


import_restaurants_db.pl       #loads restaurants only (restaurants table) to foodie db from ./menu


batch_import_menus.pl 	       #based on restaurants table in db, will populate the rest of the tables (need to watch out for keys & duplicates - best to do fresh each tiem)


clean.pl		       #clean out drinks or other non-meal entries


batch_term_doc_matrix2.pl      #this will build a text file per zipcode in ./index.  I.e. :./index/11104.idx - represents a term doc index for
			       #restaurants in that zipcode. 
