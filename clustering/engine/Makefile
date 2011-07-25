#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements. See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership. The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
#

BOOST_DIR = /usr/local/boost_1_46_1
THRIFT_DIR = /usr/local/include/thrift
LIB_DIR = /usr/local/lib

#GEN_SRC = ./cluster.cpp
GEN_SRC = ./gen-cpp/cluster_types.cpp ./gen-cpp/cluster_constants.cpp ./gen-cpp/ClusterEngine.cpp ./cluster.cpp

INDX_SRC = ./cluster_index.cpp

default: server

#server: CppServer.cpp
#	g++ -o CppServer -I${THRIFT_DIR} -I${BOOST_DIR}  -I./gen-cpp -L${LIB_DIR} -lthrift CppServer.cpp ${GEN_SRC}

server: ClusterEngine_server.cpp
	g++ -o ClusterEngine_server -I${THRIFT_DIR} -I${BOOST_DIR}  -I./gen-cpp -L${LIB_DIR} -lthrift ClusterEngine_server.cpp ${GEN_SRC} -O2


cluster: cluster.cpp cluster.h
	g++ -o Cluster -I${BOOST_DIR}  -I./ -L${LIB_DIR} ${GEN_SRC} -O3

test: cluster_index.cpp
	g++ -o cluster_index -I${BOOST_DIR}  -I./ -L${LIB_DIR} ${INDX_SRC} ./cluster.cpp -O2

clean:
	$(RM) -r Cluster
