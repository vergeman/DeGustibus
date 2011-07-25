/*
 * Cluster class
 *
 */

#include "cluster.h"

//CONSTRUCTOR
Cluster::Cluster() {}

Cluster::Cluster(string filename)
{
  //open and read file to memory
  if(_Read(filename) != 0) {
    cout <<"Error reading file"<<endl;
    exit;
  };

  //parse term-doc count file
  _Parse(terms);

  //Weight by tf*idf, return total number of food items
  this->N = _Weight();

  //normalize indices to unit vector
  _Norm();

  set_lambda(0.5);
}


void Cluster::Load(string filename) 
{
  //open and read file to memory
  if(_Read(filename) != 0) {
    cout <<"Error reading file"<<endl;
    exit;
  };

  //parse term-doc count file
  _Parse(terms);

  //Weight by tf*idf, return total number of food items
  this->N = _Weight();

  //normalize indices to unit vector
  _Norm();

  set_lambda(0.5);
}


//====RESULT API / CALC====
/*
 *S: list of seen id's (to calc dissimiliarity)
 *L: list of "liked" ideas, calc similarity
 *C: subcluster id to be REQUESTED
 *num_results: number of results desired
 */

void Cluster::set_lambda(int lambda) {
  this->lambda = lambda;
}



//returns rank-ordered list of doc id's given search terms
//this is for search bar, traverses the matrix and returns results
vector<int> Cluster::Search( vector<string> terms ) {
  vector<int> results;
  vector<id_sim> rank;

  results.clear();
  rank.clear();

  boost::unordered_map<int, double> scores;
  boost::unordered_map<int, int> length;

  cout << "Search terms: ";


  //foreach search term
  for (vector<string>::iterator it = terms.begin(); it != terms.end(); ++it) {
    //search term
    cout << *it << " ";

    //if posting list exists
    if (term_doc_index.count(*it) > 0 ) {
      //foreach doc in postings
      //get scores
      for(boost::unordered_map<int, double>::iterator id = term_doc_index[*it].begin(); id != term_doc_index[*it].end(); ++id) {

	//sum score for that doc
	if ( scores.count(id->first) > 0 ) {
	  scores[ id->first ] = scores[ id->first ] + id->second;
	}
	else {
	  scores[ id->first ] = id->second;
	}	
      }
      
      //length norm and rank
      for(boost::unordered_map<int, double>::iterator it = scores.begin(); it != scores.end(); ++it) {
	id_sim search;
	search.id2 = it->first;
	search.sim = ( it->second );
	//insert in order into ranked list
	_insert_sorted(rank, search);
      }
    }
  }  // end query iterator
  

  //push ordered doc ids for return
  for (vector<id_sim>::iterator it = rank.begin(); it != rank.end(); ++it) {
    if (! (*it).id2 == 0) {      
      results.push_back( (*it).id2 );
      //cout << (*it).id2 << " " << (*it).sim <<endl;
    }
  }

  cout <<endl;
  return results;
}




/*Rotate
 *accessor that returns suggestions
 */
vector<int> Cluster::Rotate(vector<int> L, vector<int> S, int C, int num_results) {

/*might have to make C a list if we are subclustering */    
  vector<int> id_list;
  int current_cluster = C % cluster_map.size();

  sort(S.begin(), S.end() );
  sort(L.begin(), L.end() );

  vector<int> Scopy;

  if(! S.empty()) {
    //see cluster.h - toggle true for random results, default false
    if (! RANDOM) {
      Scopy = S;
      vector<int>::iterator u = unique(Scopy.begin(), Scopy.end());
      Scopy.resize( u - Scopy.begin() );
    }
  }

  //S print
  cout <<"Items Seen:";
  for(vector<int>::iterator it = Scopy.begin(); it != Scopy.end(); ++it) {
    cout << *it << ", ";
  }
  cout <<endl;


  while( id_list.size() < num_results) {
    int result;
    //keep looping - if no results in cluster, we'll switch to another
    //and calculate similarity there
    while ( (result = _calc_Next(L, Scopy, current_cluster, lambda)) == 0 ) {    
      current_cluster = (current_cluster + 1) % cluster_map.size();
    }


    if (! binary_search(Scopy.begin(), Scopy.end(), result) ) {
      /*
       *To retrieve random results,
       *we erase the "memory" of previously seen items
       *inorder for them to be randomly generated.
       */

      if(! RANDOM) {
	Scopy.push_back(result);
      }
      sort(Scopy.begin(), Scopy.end());

      id_list.push_back( result );

      sort(id_list.begin(), id_list.end());
      cout << "doc: " << result <<endl;
      vector<int>::iterator u = unique(Scopy.begin(), Scopy.end());
      Scopy.resize( u - Scopy.begin() );

    }

    current_cluster = (current_cluster + 1) % cluster_map.size();
  }

  return id_list;
}


/*
 *NOTE: MMR Functions VERY POORLY, SWITHCED TO REGULAR SIMILARITY
 *returns id of highest ranking item, given MMR calculation
 *based on Carbonell, Goldstein, "The Use of MMR, Diversity-Based Reranking
 *for Reordering Documetns and PRoducing Summaries
 */
int Cluster:: _calc_Next (vector<int> L, vector<int> S, int cluster_id, double lambda) {
  //per item in L
  vector<id_sim> id_list;


  //bootstrap; return random in cluster first start
  if ( S.empty() ) {
    cout << "Random: cluster: " << cluster_id <<endl;

    //generate random item in cluster
    srand( time(NULL) );
    int item = rand() % cluster_map[ cluster_id ].size();

    //return the item
    int count = 0;
    for (boost::unordered_set<int>::iterator it = cluster_map[ cluster_id ].begin(); it != cluster_map[ cluster_id ].end(); ++it) {      
      if (count == item) {
	return *it;
      }
      count++;
    }

  }


  if (L.empty()) {
    cout << "Nothing Liked: cluster: " << cluster_id <<endl;

    //MMR Comparison
    if (MMR) {
      cout <<"\t using MMR" <<endl;
      //foreach doc
      for(unordered_int_string_map::iterator it = doc_term_index.begin(); it != doc_term_index.end(); ++it) {
        id_sim item;
        item.id2 = it->first;

	item.sim =  - ( (1 - lambda) * _sum_id_sim_vec( _calc_sim_list(it->first, S) ) / S.size() ) ;
	  
        if ( ! binary_search(S.begin(), S.end(), item.id2)  ) {
          _insert_sorted(id_list, item);
        }
      }

      //test output
      /*
      for(vector<id_sim>::iterator it = id_list.begin(); it != id_list.end(); ++it) {
	cout << "id: " << (*it).id2 << " score: " << (*it).sim <<endl;
      }
      */
      if( id_list.size() <= 0) {
	cout << "Empty List" <<endl;
	return 0;
      }
      //cout <<"id: " << id_list[0].id2 << " score: ";
      //printf("%.20f \n", id_list[0].sim);
      return id_list[0].id2;

    }



    //CLUSTER COMPARISON
    //for items in cluster, find the most dissimilar to ones we have seen before
    for (boost::unordered_set<int>::iterator it = cluster_map[ cluster_id ].begin(); it != cluster_map[ cluster_id ].end(); ++it) {

      //of the similar, lets invert to find most dis_similar of what's already been seen among the cluster
      id_sim sims;
      sims.id2 = *it;
      sims.sim = -  _sum_id_sim_vec(_calc_sim_list( *it, S) );


      if ( ! binary_search(S.begin(), S.end(), sims.id2) ) {
	_insert_sorted(id_list, sims);
      }
    
    }//end loop


  }//end if L.empty()

  else {
    cout <<"Something liked: cluster: " << cluster_id <<endl;
    //among each liked object - get a ranked list the item most "similarly novel"

    //among the liked, rank the centroids
    //stores a list of centroid id, and their similarity values to "liked" items
    vector<id_sim> ranked_centroids;  

    int i =0;
    //foreach liked item
    for (vector<int>::iterator it = L.begin(); it != L.end(); ++it) {

      //rank the centroids in order to that liked item
      vector<id_sim> centroid = _sim_centroids( *it);

      //keep a running sum of the score of each centroids
      ranked_centroids = _merge_ranked_centroids(ranked_centroids, centroid);

    }


    //AT THIS STAGE WE HAVE RANKED LIST OF SIMILAR CENTROIDS (thus clusters)

    //for the best cluster (loop through clusters in case there are too few elements in that particular cluster)
    for (vector<id_sim>::iterator it = ranked_centroids.begin(); it != ranked_centroids.end(); ++it) {

      //for each element in a particular cluster
      for (boost::unordered_set<int>::iterator is = cluster_map[(*it).id2].begin(); is != cluster_map[(*it).id2].end(); ++is) {

	//SIMILARITY METHODOLOGY HERE
	id_sim item;
	item.id2 = *is;
	//item.sim = _sum_id_sim_vec( _calc_sim_list(*is, L) ) - _sum_id_sim_vec( _calc_sim_list(*is, S) );
	//item.sim = lambda * ( _sum_id_sim_vec( _calc_sim_list(*is, L) ) / L.size() ) - ( (1 - lambda) * _sum_id_sim_vec( _calc_sim_list(*is, S) ) / S.size() ) ;
	//item.sim = lambda * _sum_id_sim_vec( _calc_sim_list(*is, L) );

	item.sim =_sum_id_sim_vec( _calc_sim_list(*is, L) );

	if ( ! (binary_search(L.begin(), L.end(), item.id2) ||  binary_search(S.begin(), S.end(), item.id2) ) ) {
	  _insert_sorted(id_list, item);	  
	}	

      }

    }


      
  } //end something liked MMR


  //return 0 if we couldn't find one (indicates move to another cluster
  if( id_list.empty() ) {
    //cout <<"Empty result set, moving clusters"<<endl;
    return 0;
  }
  return id_list[0].id2;
}

/*
 *Take a rank-similarity ordered list of centroid, 
 *and a given centroid add the scores up for each centroid
 *this way we have a running sum of the most similar centroid
 *for an overall list of "liked items"
 */
vector<id_sim> Cluster::_merge_ranked_centroids(vector<id_sim> ranked, vector<id_sim> centroid) {

  vector<id_sim> sorted;
  cout << "_merge_ranked_centroids" <<endl;

  if (ranked.empty() ) {
    ranked = centroid;
  }
  else {
  //merge
    for(vector<id_sim>::iterator it = ranked.begin(); it != ranked.end(); ++it) {
    
      for(vector<id_sim>::iterator ic = centroid.begin(); ic != centroid.end(); ++ic) {
	if ( (*it).id2 == (*ic).id2 ) {
	  (*it).sim += (*ic).sim;
	}
      }
    }
  }

  
  //sort  
  for(vector<id_sim>::iterator it = ranked.begin(); it != ranked.end(); ++it) {
    _insert_sorted(sorted, *it);
  }

  return sorted;
}


/*_sum_id_sim_vec
 * for a ranked list of simlarity to a given doc,
 * we sum those values to get an aggregate similarity score
 */

double Cluster::_sum_id_sim_vec(vector<id_sim> s) {
  double sum = 0.0;
  for (vector<id_sim>::iterator it = s.begin(); it != s.end(); ++it) {
    sum += ( *it ).sim;
  }
  return sum;
}


/*_calc_sim_list
 *given a doc_id, and a list of other docs
 *calculate the similarity of each list doc to the doc in question
 *return rank ordered list
 */
vector<id_sim> Cluster::_calc_sim_list(int doc_id, vector<int> list) {

  vector<id_sim> sim_list;

  //foreach element in a cluster
  for (vector<int>::iterator it = list.begin(); it != list.end(); ++it) {

    //calculate dot product betwen two documents 
    //returns struct id_sim, containg sim value, and *it doc id
    id_sim sims =  _sim( doc_id, *it );

    //add in sorted order
    _insert_sorted( sim_list, sims);

  }

  if(list.size() == 0) {
    id_sim sims;
    sims.id2 = doc_id;
    sims.sim = 0;
    _insert_sorted( sim_list, sims);
  }

  return sim_list;
}


//loops through all docs in cluster
vector<id_sim> Cluster::_calc_sim_cluster(int doc_id, int cluster_id) {

  vector<id_sim> sim_list;

  //foreach element in a cluster
  for (boost::unordered_set<int>::iterator it = cluster_map[ cluster_id ].begin(); it != cluster_map[ cluster_id ].end(); ++it) {

    id_sim sims =  _sim( doc_id, *it );
    //add in naively sorted order
    _insert_sorted( sim_list, sims);

  }
  return sim_list;
}


//Utility function to insert in id_sim vector in sorted manner
void Cluster::_insert_sorted (vector<id_sim>& sim_list, id_sim& sims) {

    //check if empty
    if ( sim_list.empty() ) {
      sim_list.insert( sim_list.begin(), sims);
    }
//otherwise find proper place
    else {
      int z = 0;
      while (z < sim_list.size() )
	{
	  
	  if ( sims.sim >= sim_list[z].sim ) {
	    sim_list.insert( sim_list.begin() + z, sims);
	    break;
	  }

	  z++;
	}
      //smallest case
      if (z == sim_list.size() ) {
	sim_list.push_back( sims );
      }
    }
}						     

//calculates dot product of two items - doc j is the "liked" list typically
id_sim Cluster::_sim(int doc_i, int doc_j) {
  id_sim sims;
  double sim = 0.0;
 
  //foreach term in doc i
  for (unordered_string_map::iterator it = doc_term_index[ doc_i ].begin(); it != doc_term_index[ doc_i ].end(); ++it) {

    //if that term from doc i is found in doc_j
    if (term_doc_index[ it->first].count(doc_j) > 0 ) {
      sim += (term_doc_index[ it->first ][ doc_j ] * it->second);
    }

  }

  sims.id2 = doc_j;
  sims.sim = sim;
  
  return sims;
} 


//given a document, gives ranked list (struct id_sim)  of most similar centroids
vector<id_sim> Cluster::_sim_centroids(int doc_i) {
  cout << "_sim_centroid" << " " << doc_i <<endl;
  vector<id_sim> centroid_rank;

  //foreach centroid
  for (unordered_int_string_map::iterator it = centroid_map.begin(); it != centroid_map.end(); ++it) {
    double sim = 0.0;
    id_sim cluster;
    //for each word in doc_i
    for (unordered_string_map::iterator id = doc_term_index[ doc_i ].begin(); id != doc_term_index[ doc_i ].end(); ++id) {
      sim += ( (it->second)[ id->first ] * id->second );
      //cout << sim <<endl;
    } 
    cluster.id2 = it->first;
    cluster.sim = sim;

    _insert_sorted(centroid_rank, cluster);
  }

  //print centroid
  //for (vector<id_sim>::iterator it = centroid_rank.begin(); it != centroid_rank.end(); ++it) {
  //  cout << (*it).id2 << " " << (*it).sim << endl;
  //}

  return centroid_rank;
}


//===CLUSTERING===

/*Kmeans:
 *perform clustering on all or a specific list
 *sets cluster_set_map cluster_map internal class variable
 */

void Cluster::Kmeans(int q, int iterations) {
  vector<int> id_list;  
  vector<int> seeds;
  time_t start, end;
  //container of centroids (large docs), centroid is a doc - unordered_string_map
  //centroid id => "doc"

  //cluster collection: map of cluster id => set of vector ids
  //typedef boost::unordered_map<int, boost::unordered_set<int> > cluster_set_map;
  //cluster_set_map cluster_map;

  int K = (int) sqrt(this->N); 
  seeds =  _selectRandomSeeds( K );

  //set initial centroid seeds
  for (int k = 0; k < K; k++) {
    centroid_map.insert( unordered_int_string_map::value_type( k, doc_term_index[ seeds[k] ] ));
  }


  int I = iterations;
  int j = 0;
  //foreach cluster (set to new cluster map each iteration) (declared in header)
  //stopping condition.
  cout << "Starting iterations" <<endl;
  while (j < I) {
    cout << "Iteration: " << j << endl;


    cluster_map.clear();
    for (int k = 0; k < K; k++) {
      //cluster = {}      
      boost::unordered_set<int> cluster_list;  //vector members in cluster
      cluster_map.insert(cluster_set_map::value_type( k, cluster_list ) );
    }

    //foreach item..
    //reassignment of vectors to a cluster
    //for (int n = 0; n < N; n++) {
    int n = 0;
    for (unordered_int_string_map::iterator i_doc_term = doc_term_index.begin(); i_doc_term != doc_term_index.end(); ++i_doc_term) {
	//j = min |uj - xn|
	double min_score = 1000.0;
	double cluster_score;
	int min_cluster;


	for (int z = 0; z < K; z++) {

	  if(min_score > (cluster_score = _distance(centroid_map[z], i_doc_term->second)  )) {

	    min_score = cluster_score;
	    min_cluster = z;
	  }

	  //cout << "score: " << double( _distance(centroid_map[z], doc_term_index[n])) << endl;
	  //cout << "doc: " << n << " Cluster score: " << cluster_score << endl;
	}

	//cout << "doc: " << n << " goes in cluster: " << min_cluster << " score: " << min_score << endl;

	//cluster = cluster U xn
	cluster_map[min_cluster].insert( i_doc_term->first );
	//cout << "inserting cluster: " << min_cluster << "item: " << i_doc_term->first <<endl;
	n++;
    }

    //recompute centroid from members of cluster
    //foreach cluster
    cout << "Recomputing Clusters . . ." <<endl;
    for (int z = 0; z < K; z++) {
      //uk = 1/|clusterk| sum( vectors in cluster k)
      centroid_map[z] = _centroid( cluster_map[z] );
    }


    j++;
  }


  //print centroids    
  /*  
  for (unordered_int_string_map::iterator icentroid = centroid_map.begin(); icentroid != centroid_map.end(); ++icentroid) {
    cout << icentroid->first << " : " << endl;
    for (unordered_string_map::iterator ivec = (icentroid->second).begin(); ivec != (icentroid->second).end(); ++ivec) {
      cout << "\t" << ivec->first << ":" << ivec->second << endl;
    }      
  }
  */
    
  //print cluster memebership
  /*
  for (cluster_set_map::iterator i_set = cluster_map.begin(); i_set != cluster_map.end(); ++i_set) {
    cout << i_set->first << "\t" << endl;
    for (boost::unordered_set<int>::iterator i_list = i_set->second.begin(); i_list != i_set->second.end(); ++i_list) {

      cout << " " << *i_list;
    }
    cout <<endl;
  }
  */

}


//calculates average of vectors
boost::unordered_map<string, double> Cluster::_centroid(boost::unordered_set<int>& cluster_list) {

  unordered_string_map centroid;

  int cluster_size = cluster_list.size();
  
  for (boost::unordered_set<int>::iterator it = cluster_list.begin(); it != cluster_list.end(); ++it) {

    //add each element of vector to centroid
    for (unordered_string_map::iterator ivec = doc_term_index[ *it ].begin(); ivec != doc_term_index[ *it ].end(); ++ivec) {
  
      //element (term) doesn't exist, we add it to the map
      if ( centroid.count ( ivec->first ) == 0) {
	//cout << "ivec second: " << ivec->second <<endl;
	//cout << "cluster_size: " << cluster_size <<endl;

	centroid.insert(unordered_string_map::value_type( ivec->first, double( (double)ivec->second / cluster_size ) ));
      }
      else {
	centroid[ivec->first] += double( ((double)ivec->second / cluster_size) );
      }

    }
  }    
  return centroid;
}




double Cluster::_distance( unordered_string_map& centroid, unordered_string_map& doc) {
  /*doc:
   *string=>count
   *string=>count
   *
   */
  //cout << "_distance" <<endl;

  //normalize
  int total_doc_freq = 0;
  int total_centroid_freq = 0;
  double doc_norm;
  double centroid_norm;
  double score = 0.0;

  //cout <<"doc_norm: " << doc_norm <<endl;
  //cout <<"centroid_norm: " << centroid_norm <<endl;

  //score all doc matches in centroid
  for (unordered_string_map::iterator idoc = doc.begin(); idoc != doc.end(); ++idoc) {
    score += pow(idoc->second - centroid[ idoc->first] , 2);
    //cout << idoc->first << ": " << idoc->second << " : " << centroid[idoc->first] << endl;
  }

  //score remaining terms in centroids
  for (unordered_string_map::iterator icentroid = centroid.begin(); icentroid != centroid.end(); ++icentroid) {
    if ( doc.count ( icentroid->first ) == 0) {
      score += pow( icentroid->second, 2);
    }
  }

  return sqrt( score );
}


//returns random POSITIONS that will correspond to id's
//todo: check duplicate possibility p(1/10000) but exists
vector<int> Cluster::_selectRandomSeeds(int K) {
  vector<int> seeds (K, 0);
  int size = doc_term_index.size();

  int id;
  double r;

  //build a copy list of item ids
  vector<int> nums;
  for (unordered_int_string_map::iterator i = doc_term_index.begin(); i != doc_term_index.end(); ++i) {
    nums.insert(nums.begin(), i->first );
  }

  srand( time(NULL) );

  for (int k = 0; k < K; k++) {
    //random seed
    r = (double) rand() / (double) RAND_MAX;
    //cout << "r: " << r << endl;
    id = (int) (r * (size-k));
    //take random position from nums (vector of ids) and that is a seed
    seeds[k] = nums[id];
    //cout << nums[id] <<endl;
    //remove that seed and shrink available nums accordingly

    nums.erase(nums.begin() + id );
  }

  cout << "Finished _selectRandomSeeds(" << K << ")" <<endl;
  return seeds;
}







//==PARSING=====

//READ

int Cluster::_Read(string filename) 
{
  string line;
  ifstream myfile ( filename.c_str() );
  
  if (myfile.is_open())
    {
      while ( myfile.good() )
	{
	  getline (myfile, line);
	  //build vector
	  terms.push_back(line);
	}
      myfile.close();
    }
  else 
    {
      return -1;
    }    
  cout <<"Reading file . . . "<< filename << endl;
  return 0;
}



//PARSE

int Cluster::_Parse(vector<string> terms) 
{
  
  for (int k = 0; k < terms.size(); k++) {    
    _ParseLine(terms[k]);
  }  
  //save some memory
  terms.clear();
  return 0;
}



//PARSELINE

int Cluster::_ParseLine(string line) {
  typedef vector<string> split_vector_type;
  typedef boost::unordered_map<int, double> unordered_double_map;
  
  split_vector_type LineVec;
  split_vector_type PairVec;
  int vec1;
  int vec2;
  string temp;
  
  //trim line
  boost::trim(line);

  //split to space delimited tokens word N:1 docid:count docid:count
  boost::split( LineVec, line, boost::is_any_of(" ") , boost::algorithm::token_compress_on );
  
  if( !LineVec[0].empty() ){

    unordered_double_map doc_hash;      //inner of term-doc index    
    unordered_string_map term_hash;  //inner of doc index

    //double norm =0.0;
     
    for (int k =2; k < LineVec.size(); k++) {
      temp = LineVec[k];

      //cout << temp << endl;
      boost::trim(temp);
      
      //split to space delimited postings list tokens: N 1, docid count, ..
      boost::split( PairVec, temp, boost::is_any_of(":"), boost::algorithm::token_compress_on );
      
      //TERM-DOC POPULATE: populate docid:counts
      vec1 = atoi( PairVec[0].c_str() );
      vec2 = atoi( PairVec[1].c_str() );

      //norm += pow(vec2, 2);
      doc_hash.insert(unordered_double_map::value_type( vec1, (double)vec2 ) );

      doc_term_index[ vec1 ][ LineVec[0] ] = (double) vec2;
    }
    

    //cout << "size: " << doc_hash.size() << endl;
    term_doc_index.insert(unordered_map::value_type(LineVec[0], doc_hash));    
  
          
  }//end if


  return 0;
}


//take term frequencies, and reweight indicies to tf*idf
int Cluster::_Weight() {
  cout << "Calculating tf*idf weights" <<endl;

  int N = doc_term_index.size();  //num docs

  //TERM-DOC
  //foreach term
  //it->first: term, it->second: (docid, term freq)
  for (unordered_map::iterator it = term_doc_index.begin(); it != term_doc_index.end(); ++it) {

    int df = 0;

    //get document frequency
    //doc->term count
    //iu->first: docid, iu->second: (term, term_freq)
    for(boost::unordered_map<int, double>::iterator iu = term_doc_index[ it->first ].begin(); iu != term_doc_index[ it->first].end(); ++iu) {
      df += iu->second;
    }

    //replace w/ tfidf
    int tf = 0;
    double idf;
    double tfidf;
    for(boost::unordered_map<int, double>::iterator iu = term_doc_index[ it->first ].begin(); iu != term_doc_index[ it->first].end(); ++iu) {
      tf = iu->second;
      idf = log( N / df);
      tfidf = tf * idf;

      iu->second = tfidf;
      doc_term_index[iu->first][it->first] = tfidf;
    }
  
  }


  return N;
}

//normalize
int Cluster::_Norm() {
  cout << "Normalizing values. . ." <<endl;

  //foreach doc (doc -> (term, count) )
  for(unordered_int_string_map::iterator it = doc_term_index.begin(); it != doc_term_index.end(); ++it) {

    //foreach term in doc (term, count)
    double sum = 0;
    double norm = 0;
    for (unordered_string_map::iterator iu = doc_term_index[it->first].begin(); iu != doc_term_index[it->first].end(); ++iu) {
      sum += pow(iu->second, 2);
    }

    norm = sqrt(sum);

    //each term in doc
    for (unordered_string_map::iterator iu = doc_term_index[it->first].begin(); iu != doc_term_index[it->first].end(); ++iu) {
      iu->second = iu->second / norm; //normalize doc_term_index value

      term_doc_index[iu->first][it->first] = iu->second; //norm term-doc_index values
    }

  }


  return 0;
}
