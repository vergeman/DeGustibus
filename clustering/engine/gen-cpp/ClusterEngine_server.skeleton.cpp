// This autogenerated skeleton file illustrates how to build a server.
// You should copy it to another filename to avoid overwriting it.

#include "ClusterEngine.h"
#include <protocol/TBinaryProtocol.h>
#include <server/TSimpleServer.h>
#include <transport/TServerSocket.h>
#include <transport/TBufferTransports.h>

using namespace ::apache::thrift;
using namespace ::apache::thrift::protocol;
using namespace ::apache::thrift::transport;
using namespace ::apache::thrift::server;

using boost::shared_ptr;

using namespace ClusterEngine;

class ClusterEngineHandler : virtual public ClusterEngineIf {
 public:
  ClusterEngineHandler() {
    // Your initialization goes here
  }

  void getItems(std::vector<int32_t> & _return, const std::vector<int32_t> & L, const std::vector<int32_t> & S, const int32_t C, const int32_t num_results) {
    // Your implementation goes here
    printf("getItems\n");
  }

  void getSearch(std::vector<int32_t> & _return, const std::vector<std::string> & terms) {
    // Your implementation goes here
    printf("getSearch\n");
  }

};

int main(int argc, char **argv) {
  int port = 9090;
  shared_ptr<ClusterEngineHandler> handler(new ClusterEngineHandler());
  shared_ptr<TProcessor> processor(new ClusterEngineProcessor(handler));
  shared_ptr<TServerTransport> serverTransport(new TServerSocket(port));
  shared_ptr<TTransportFactory> transportFactory(new TBufferedTransportFactory());
  shared_ptr<TProtocolFactory> protocolFactory(new TBinaryProtocolFactory());

  TSimpleServer server(processor, serverTransport, transportFactory, protocolFactory);
  server.serve();
  return 0;
}

