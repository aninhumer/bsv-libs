/*****************************************************************************
Sockets
=======
Alex Horsman, August 2012

This library builds on Pipes to provide an abstraction for bidirectional
connections, in the form of a typeclass Socket, and a module mkStream which
connects two instances of Socket together.

Instances are provided for the following standard library interfaces:
GetPut: GetPut.
ClientServer: Server and Client.
Vector: Vectors of Socket instances.

*****************************************************************************/

package Sockets;

import GetPut::*;
import Pipes::*;

//The Socket typeclass has three arguments: socketT is the type which
//is a Socket, and inT and outT are the types of data it accepts and
//provides, respectively.
typeclass Socket#(type socketT, type inT, type outT)
//It is necessary that an interface only be a Socket of only one
//type of data, otherwise it would be ambigous which data should be
//transferred by mkStream. These dependencies enforce this.
dependencies (socketT determines (inT, outT));
	function Get#(outT) socketToGet(socketT x);
	function Put#(inT)  socketToPut(socketT x);
endtypeclass


//This module accepts any two Sockets having matching in and out
//types, and creates a connection between them. The Sockets need
//not be of the same interface.
module mkStream#(fstT x, sndT y)(Empty) provisos(
	Socket#(fstT,lFlowT,rFlowT),
	Socket#(sndT,rFlowT,lFlowT));

	mkFlow(socketToGet(x),socketToPut(y));
	mkFlow(socketToGet(y),socketToPut(x));
endmodule


instance Socket#(GetPut#(dataT),dataT,dataT);
	function socketToGet(gp) = tpl_1(gp);
	function socketToPut(gp) = tpl_2(gp);
endinstance


import ClientServer::*;

instance Socket#(Server#(inT,outT),inT,outT);
	function socketToGet(s) = s.response;
	function socketToPut(s) = s.request;
endinstance

instance Socket#(Client#(outT,inT),inT,outT);
	function socketToGet(c) = c.request;
	function socketToPut(c) = c.response;
endinstance


import Vector::*;

instance Socket#(Vector#(n,socketT),Vector#(n,inT),Vector#(n,outT))
	provisos(Socket#(socketT,inT,outT));
	function socketToGet(sockets) = interface Get;
		function getter(x) = socketToGet(x).get();
		method get = mapM(getter,sockets);
	endinterface;
	function socketToPut(sockets) = interface Put;
		function putter(x,y) = socketToPut(x).put(y);
		method put(xs) = zipWithM_(putter,sockets,xs);
	endinterface;
endinstance


endpackage
