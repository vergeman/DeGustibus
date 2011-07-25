#!/usr/local/bin/thrift --gen cpp

namespace cpp ClusterEngine

service ClusterEngine {

  list<i32> getItems(1:list<i32> L, 2:list<i32> S, 3:i32 C, 4:i32 num_results),

  list<i32> getSearch(1:list<string> terms),


}
