
#include "cluster.h"





int main () {
  Cluster myCluster("../../crawl/index/10027.idx");
  //Cluster myCluster2("../../index/11104.idx");

  myCluster.Kmeans(40, 2);
  //myCluster2.Kmeans(40, 100);

  vector<int> L;
  //L.push_back(149875);
  //L.push_back(146445);
  vector<int> S;

  

  S.push_back(149732);
  S.push_back(149874);
    
  S.push_back(146457);
  S.push_back(149740);
  S.push_back(149826);
  /*
  S.push_back(146333);
  S.push_back(177248);
  S.push_back(149875);
  */
  int C = 5;
  int num_results = 3;
  /*
  vector<int> results = myCluster.Rotate(L, S, C, num_results);

  for(vector<int>::iterator it = results.begin(); it != results.end(); ++it) {
    cout << *it <<endl;
  }
  */


  //TEST SEARCG
  vector<string> searches;
  searches.push_back("chicken");
  searches.push_back("club");
  searches.push_back("sandwich");

  vector<int> results = myCluster.Search(searches);

  for(vector<int>::iterator it = results.begin(); it != results.end(); ++it) {
    cout << *it <<endl;
  }
  

  /*
    //TEST SIM
  for (int q= 0; q < 40; q++) {
    cout << "Cluster: " << q << endl;

    vector<id_sim> temp = myCluster._calc_sim_cluster(8196, q);

    for (int z = 0; z< temp.size(); z++) {
      cout <<"\t" << temp[z].id2 << ": " << temp[z].sim <<endl; 
    }

  }
  */

  cout <<"DONE" <<endl;


  return 0;
}
