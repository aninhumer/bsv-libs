/*****************************************************************************
Pipes
=====
Alex Horsman, July 2012

This library is intended to provide a more consistent and flexible semantics
for unidirectional connections than the built in Connectable library.

Its key elements are the Source and Sink typeclasses, and the mkFlow module.
Any instance of Source can be connected to any instance of Sink using the
mkFlow module. The instances provided by this library are such that most uses
of mkConnection to provide a unidirectional flow of data can be directly
replaced with mkFlow, with the caveat that the argument order may need
reversing to ensure the Source and Sink are in the correct order.

In addition to a direct replacement, in many cases the logic used to expose
a Get and Put from other interfaces can be removed, as there are already
instances of Source or Sink defined for them. For example:

	mkConnection(server.response, toPut(fifo));

can be reduced to simply:

	mkFlow(server, fifo);

as ClientServer::Server and FIFO::FIFO are already instances of both Source
and Sink. This makes the code easier to read, as it eliminates incidental
complexity, and also makes the direction clear, by enforcing consistent left
to right usage.

Instances are provided for the following standard library interfaces:
GetPut: Get, Put and GetS.
ClientServer: Server and Client.
FIFOs: FIFO, FIFOF, SyncFIFOIfc, (Sync)FIFOLevelIfc, (Sync)FIFOCountIfc.
Vector: Vectors of Source or Sink instances.

This library also provides an interface Pipe, which is very similar to the
Server interface, but with the intention that it be used to distinguish a
module which data flows through from one place to another, as opposed to one
which is accessed by a single client.

*****************************************************************************/

package Pipes;

import GetPut::*;

/*****************************************************************************
 Source and Sink
 *****************************************************************************/

//The typeclasses have two arguments: srcT/snkT is the type which is the
//Source/Sink itself, and outT/inT is the type of data it provides/accepts.

typeclass Source#(type srcT, type outT)
//It is necessary that an interface only be a Source (or Sink) of only one
//type of data, otherwise it would be ambigous which data should be
//transferred by mkFlow. These dependencies enforce this.
dependencies(srcT determines outT);
	function Get#(outT) sourceToGet(srcT x);
endtypeclass

typeclass Sink#(type snkT, type inT)
dependencies(snkT determines inT);
	function Put#(inT) sinkToPut(snkT x);
endtypeclass


//This module connects any Source which provides a given type to any Sink
//which accepts the same type. The Source and Sink themselves need not be
//the same kind of interface.
module mkFlow#(srcT x, snkT y)(Empty)
	provisos(Source#(srcT,dataT),Sink#(snkT,dataT));

	rule flow;
		let v <- sourceToGet(x).get();
		sinkToPut(y).put(v);
	endrule
endmodule


/*****************************************************************************
 Pipe
 *****************************************************************************/

interface Pipe#(type inT, type outT);
	interface Put#(inT)  in;
	interface Get#(outT) out;
endinterface

instance Source#(Pipe#(_,outT),outT); 
	function sourceToGet(src) = src.out;
endinstance

instance Sink#(Pipe#(inT,_),inT);
	function sinkToPut(snk) = snk.in;
endinstance

/*****************************************************************************
 Instances
 *****************************************************************************/

//Trivial instances for Get and Put.
instance Source#(Get#(outT),outT);
	function sourceToGet(s) = s;
endinstance

instance Sink#(Put#(inT),inT);
	function sinkToPut(s) = s;
endinstance

instance Source#(GetS#(outT),outT);
	function sourceToGet(s) = interface Get;
		method ActionValue#(outT) get();
			let v = s.first;
			s.deq();
			return v;
		endmethod
	endinterface;
endinstance


//The Connectable library provides instances to allow Vectors of Connectable
//interfaces to be connected. These instances similarly allow a Vector of
//Sources to be connected to a corresponding Vector of Sinks.
//TODO: Add Tuples and ListN.
import Vector::*;

instance Source#(Vector#(n,srcT),Vector#(n,outT)) provisos(Source#(srcT,outT));
	function sourceToGet(srcs);
		return interface Get;
			function getter(i) = sourceToGet(srcs[i]).get();
			method get() = genWithM(getter);
		endinterface;
	endfunction
endinstance

instance Sink#(Vector#(n,snkT),Vector#(n,inT)) provisos(Sink#(snkT,inT));
	function sinkToPut(snks);
		return interface Put;
			function putter(x,snk) = sinkToPut(snk).put(x);
			method put(ins) = zipWithM_(putter,ins,snks);
		endinterface;
	endfunction
endinstance


//Instances for FIFO.
import FIFO::*;

instance Source#(FIFO#(dataT),dataT);
	function sourceToGet(fifo) = toGet(fifo);
endinstance

instance Sink#(FIFO#(dataT),dataT);
	function sinkToPut(fifo) = toPut(fifo);
endinstance


import FIFOF::*;

instance Source#(FIFOF#(dataT),dataT);
	function sourceToGet(fifo) = toGet(fifo);
endinstance

instance Sink#(FIFOF#(dataT),dataT);
	function sinkToPut(fifo) = toPut(fifo);
endinstance


import Clocks::*;

instance Source#(SyncFIFOIfc#(dataT),dataT);
	function sourceToGet(fifo) = toGet(fifo);
endinstance

instance Sink#(SyncFIFOIfc#(dataT),dataT);
	function sinkToPut(fifo) = toPut(fifo);
endinstance


import FIFOLevel::*;

instance Source#(FIFOLevelIfc#(dataT,_),dataT);
	function sourceToGet(fifo) = toGet(fifo);
endinstance

instance Sink#(FIFOLevelIfc#(dataT,_),dataT);
	function sinkToPut(fifo) = toPut(fifo);
endinstance

instance Source#(SyncFIFOLevelIfc#(dataT,_),dataT);
	function sourceToGet(fifo) = toGet(fifo);
endinstance

instance Sink#(SyncFIFOLevelIfc#(dataT,_),dataT);
	function sinkToPut(fifo) = toPut(fifo);
endinstance

instance Source#(FIFOCountIfc#(dataT,_),dataT);
	function sourceToGet(fifo) = toGet(fifo);
endinstance

instance Sink#(FIFOCountIfc#(dataT,_),dataT);
	function sinkToPut(fifo) = toPut(fifo);
endinstance

instance Source#(SyncFIFOCountIfc#(dataT,_),dataT);
	function sourceToGet(fifo) = toGet(fifo);
endinstance

instance Sink#(SyncFIFOCountIfc#(dataT,_),dataT);
	function sinkToPut(fifo) = toPut(fifo);
endinstance


//It should be noted that although this library provides instances of
//Source and Sink for Client and Server, the semantics of these are
//unidirectional, whereas the Connectable instance is bidirectional.
//If the same behaviour as mkConnection is desired using this library,
//separate connections must be made in both directions.
import ClientServer::*;

instance Source#(Server#(_,outT),outT);
	function sourceToGet(srv) = srv.response;
endinstance

instance Sink#(Server#(inT,_),inT);
	function sinkToPut(srv) = srv.request;
endinstance

instance Source#(Client#(outT,_),outT);
	function sourceToGet(srv) = srv.request;
endinstance

instance Sink#(Client#(_,inT),inT);
	function sinkToPut(srv) = srv.response;
endinstance


endpackage
