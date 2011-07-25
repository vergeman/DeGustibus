#ifndef CLUSTER_H
#define CLUSTER_H

//header includes
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <stack>

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>

#include <boost/unordered_set.hpp>
#include <boost/unordered_map.hpp>
#include <boost/algorithm/string.hpp>

using namespace std;


/**
 *struct id_sim:
 *a basic pairs container for similarity computations
 *id2: is the item (document) id
 *sim: similarity value 
 */
struct id_sim {
  int id2;
  double sim;
};

/**
 *Cluster class
 *houses term-doc, doc-doc indices
 *and performs internal K-means operations
 *also has accessor functions Search & Rotate
 *that get called by users.
 *
 */
class Cluster {

 private:
  vector<string> terms;  /** raw terms list used for input */

  //Term Document Matrix types

  /**
   *internal typedef for term_document matrix 
   */
  typedef boost::unordered_map<string, boost::unordered_map<int, double> > unordered_map;

  /**
   *typedef for term_document matrix, uses unordered_map 
   */
  typedef boost::unordered_map<string, double> unordered_string_map;

  //Doc Matrix
  /**
   *typedef for doc-doc matrix
   */
  typedef boost::unordered_map<int, unordered_string_map > unordered_int_string_map;

  /**
   * list of cluster membership (hash => docids)
   */
  typedef boost::unordered_map<int, boost::unordered_set<int> > cluster_set_map;

  /**
   * term-doc matrix hash (term -> (docid -> count) ) 
   */
  unordered_map term_doc_index;  

  /**
   * doc-matrix (docid -> (term -> count)) 
   */
  unordered_int_string_map doc_term_index;
  
  /**
   * hash of cluster_id => unordered_set of ids
   */
  cluster_set_map cluster_map;

  /**
   * has of centroids (int==>(string=>double) )
   */
  unordered_int_string_map centroid_map; 


  /**
   * number of food items
   */
  int N;

  /**
   * coefficient for MMR
   */
  int lambda; 

  /**
   * enables or disables "random" recommendations for comparison
   */
  #define RANDOM false
  
  /**
   * enable/disable "MMR" recommendation for comparison
   */
  #define MMR false

 public:

  /**
   * default constructor (not implemented)
   */
  Cluster();

  /**
   * constructor
   * @param filename is a string arg representing the final
   * term-doc index output
   * by the crawl
   */
  Cluster(string filename);  

  /**
   * Load: mimics constructor - called by thrift
   * @param filename is a string arg representing the final
   * term-doc index output
   * by the crawl
   */
  void Load(string filename);

  //Index Building Functions
  /**
   * _Read: internal index building function, opens and reads the file
   * representing term-doc index
   * @param filename is the term-doc index
   */
  int _Read(string filename);
  
  /**
   * _Parse: parses a vector of terms 
   * @param terms is a vector of terms
   */
  int _Parse(vector<string> terms);

  /**
   * _ParseLine parses each line
   * @param line is a string that represents a line of text
   */
  int _ParseLine(string line);

  /**
   *_Weight translates the term frequency values in the index into a
   * tf*idf weights and repopulates the matrix
   */
  int _Weight();

  /**
   * _Norm normalizes the weights so that the values are representative
   * of unit vectors
   */
  int _Norm();

  //Kmeans functions
  /**
   * Kmeans: an implementation of Kmeans.
   * @param q deprecated - automatically calculates sqrt N items as seeds
   * @param iterations: number of clustering iterations to perform
   */
  void Kmeans(int q, int iterations);

  /**
   * _selectRandomSeeds returns a vector of item id's representing randomly chosen seeds.
   * @param N is an integer of how many seeds to select.
   * @return vector of item ids that are the seeds
   */
  vector<int> _selectRandomSeeds(int N);

  /**
   *_distance: internal K-means function that measures distance from
   * centroid to item
   * @param centroid: reference to centroid hash map
   * @param doc: reference to document id
   * @return distance computation
   */
  double _distance(unordered_string_map& centroid, unordered_string_map& doc);

  /**
   *_centroid: calculates the average of the documents, creates the centroid
   * @param cluster_list represents a list of documents in a cluster
   * @return unordered_string_map represents centroid.
   */
  unordered_string_map _centroid(boost::unordered_set<int>& cluster_list);

  //Accessor Functions with Client

  /**
   * Rotate: is the accessor function called by the client, and returns
   * a vector of item id's that represent suggestions, calculated according to the inputs.
   * @param L is a vector of doc id's representing items that a client requests for more similar
   * @param S is a vector of doc id's representing already "seen" items, of which dissimilar items are to be calculated from.
   * @param C is the cluster id to start calcluations from
   * @param num_results represents the number of results to return
   * @return list of item ids
   */
  vector<int> Rotate(vector<int> L, vector<int> S, int C, int num_results);

  /**
   * Search: an accessor function called by the client to return a vector of document (item) id's that
   * are the search results.
   * @param terms accords to a string of search terms.
   */
  vector<int> Search(vector<string> terms);

  //Calculation Functions

  /**
   * _calc_Next returns a single item, given the preferences sent by the client.  It is
   * called repeatedly in Rotate to generate the desired results
   * @param L is a vector of doc id's representing items that a client requests for more similar
   * @param S is a vector of doc id's representing already "seen" items, of which dissimilar items are to be calculated from.
   * @param cluster_id is the cluster id to start calcluations from
   * @param lambda: deprecated, was used in MMR calculations, but was found not to be a good basis for calculation.
   * @return will return 0 if no item was found - this is used to indicate we move to the next cluster and calculate
   * again.  otherwise it is the item Id.
   */
  int _calc_Next (vector<int> L, vector<int> S, int cluster_id, double lambda);

  /**
   *set_lambda is a setter method to set lambda value.  Not used in current implementation
   * @param lambda is an integer
   */
  void set_lambda(int lambda);

  /**
   * _calc_sim_list takes a given item, and a list of other items, and calculates the similarities between them 
   * returning a vector of struct id_sim's.
   * @param doc_id is an integer representing the document to be compared
   * @param list is a vector of other docs (usually representing S, or L) of which to calculate similarities
   * @return a vector of pairs that house the similarity values
   */
  vector<id_sim> _calc_sim_list(int doc_id, vector<int> list);

  /**
   * _calc_sim_cluster takes an item id, and a cluster_id, and calculates the similarities between all docs
   * in that cluster, returning a vector of struct id_sims with the according values.
   * @param doc_id is an integer representing the document to be compared
   * @param cluster_id is the interal cluster_id from which all docs are to be compared.
   * @return a vector of pairs that house the similarity values
   */
  vector<id_sim> _calc_sim_cluster(int doc_id, int cluster_id);

  /**
   * _sum_id_sim_vec takes a vector of similarity calculations and sums them for an aggregate score.
   * this is used to calculate the relative ranking of multiple documetns against a list.  (often having called
   * _calc_sim_list / _calc_sim_cluster beforehand, and passing the results to this function.
   * @param s is a vector of struct id_sim pairs.
   * @return an aggregate score
   */
  double _sum_id_sim_vec(vector<id_sim> s);

  /**
   * _merge_ranked_centroids: take a rank-similarity ordered list of centroid, and a given centroid add 
   * the scores up for each centroid.  This way we have a running sum of the most similar centroid
   * for an overall list of "liked items"
   * @param ranked is a vector of struct id_sim pairs that are in ranked order
   * @param centroid: current centroid
   * @return vector of struct id_sim
   */
  vector<id_sim> _merge_ranked_centroids(vector<id_sim> ranked, vector<id_sim> centroid);

  /**
   * _sim_centroids, given a document, gives ranked list (struct id_sim)  of most similar centroids
   * @param doc_i an item id integer
   * @return vector of centroids, rank similarity ordered
   */
  vector<id_sim> _sim_centroids(int doc_i);

  /**
   * insert_sorted is a utility function that takes a vector of struct pairs, and inserts a pair into 
   * that list, while maintaing sorted order of that list (based on similarity value)
   * @param sim_list is a reference to the list to be inserted into
   * @param sims is a reference to the pair being inserted.
   */
  void _insert_sorted( vector<id_sim>& sim_list, id_sim& sims);

  /**
   *_sim returns the similarity calculation between two documents.
   *@param doc_i item id
   *@param doc_j item id2
   *@return id_sim is a pair that reperesents doc J's id value
   */
  id_sim _sim(int doc_i, int doc_j);

};

#endif

