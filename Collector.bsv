/*****************************************************************************
Collector
=========
Alex Horsman, July 2012

This library provides modules which can be used to convert between large data
types, and streams of smaller parts used e.g. for transfer. As a special case
this includes serial to parallel. The modules mkCollectorLE and mkCollectorBE
accept a stream of parts on their input and output a reconstructed larger value
in little endian or big endian order respectively. Similarly mkSplitterLE and
mkSplitterBE accept a large value on their input and output a stream of parts
in little or big endian order.

It is important to note that as a result of this use case, these two modules
do NOT provide a single response for each request. mkCollector will produce
one response for every N requests, and mkSplitter will produce N responses
for each request, where N is the number of parts which fit into the whole.

*****************************************************************************/

package Collector;

import GetPut::*;
import Vector::*;

import Pipes::*;
import RegUtils::*;

module mkCollectorLE(Pipe#(partT,wholeT)) provisos(
	Bits#(partT,partSize),Bits#(wholeT,wholeSize),
	//Ensure wholeT splits into partTs exactly
	Div#(wholeSize,partSize,n),Mul#(partSize,n,wholeSize));

	let nval = fromInteger(valueof(n));

	Reg#(wholeT) whole <- mkRegU;
	Reg#(Vector#(n,partT)) parts = shadowReg(whole);

	Reg#(UInt#(TLog#(TAdd#(n,1)))) pos <- mkReg(0);

	interface Put in;
		method Action put(x) if (pos < nval);
			parts[pos] <= x;
			pos <= pos + 1;
		endmethod
	endinterface
	interface Get out;
		method ActionValue#(wholeT) get() if (pos == nval);
			pos <= 0;
			return whole;
		endmethod
	endinterface
endmodule

module mkSplitterLE(Pipe#(wholeT,partT)) provisos(
	Bits#(partT,partSize),Bits#(wholeT,wholeSize),
	//Ensure wholeT splits into partTs exactly
	Div#(wholeSize,partSize,n),Mul#(partSize,n,wholeSize));

	let nval = fromInteger(valueof(n));

	Reg#(wholeT) whole <- mkRegU;
	Reg#(Vector#(n,partT)) parts = shadowReg(whole);

	Reg#(UInt#(TLog#(TAdd#(n,1)))) pos <- mkReg(nval);

	interface Put in;
		method Action put(x) if (pos == nval);
			pos <= 0;
			whole <= x;
		endmethod
	endinterface
	interface Get out;
		method ActionValue#(partT) get() if (pos < nval);
			pos <= pos + 1;
			return parts[pos];
		endmethod
	endinterface
endmodule

module mkCollectorBE(Pipe#(partT,wholeT)) provisos(
	Bits#(partT,partSize),Bits#(wholeT,wholeSize),
	//Ensure wholeT splits into partTs exactly
	Div#(wholeSize,partSize,n),Mul#(partSize,n,wholeSize));

	let maxval = fromInteger(valueof(n) - 1);

	Reg#(wholeT) whole <- mkRegU;
	Reg#(Vector#(n,partT)) parts = shadowReg(whole);

	Reg#(Int#(TAdd#(TLog#(n),1))) pos <- mkReg(maxval);

	interface Put in;
		method Action put(x) if (pos >= 0);
			pos <= pos - 1;
			parts[pos] <= x;
		endmethod
	endinterface
	interface Get out;
		method ActionValue#(wholeT) get() if (pos == -1);
			pos <= maxval;
			return whole;
		endmethod
	endinterface
endmodule

module mkSplitterBE(Pipe#(wholeT,partT)) provisos(
	Bits#(partT,partSize),Bits#(wholeT,wholeSize),
	//Ensure wholeT splits into partTs exactly
	Div#(wholeSize,partSize,n),Mul#(partSize,n,wholeSize));

	let maxval = fromInteger(valueof(n) - 1);

	Reg#(wholeT) whole <- mkRegU;
	Reg#(Vector#(n,partT)) parts = shadowReg(whole);

	Reg#(Int#(TAdd#(TLog#(n),1))) pos <- mkReg(-1);

	interface Put in;
		method Action put(x) if (pos == -1);
			pos <= maxval;
			whole <= x;
		endmethod
	endinterface
	interface Get out;
		method ActionValue#(partT) get() if (pos >= 0);
			pos <= pos - 1;
			return parts[pos];
		endmethod
	endinterface
endmodule

import StmtFSM::*;
import Testing::*;

typedef 4 PartSize;
typedef 5 NumParts;

typedef Bit#(PartSize) Part;
typedef Bit#(TMul#(NumParts,PartSize)) Whole;
typedef Vector#(NumParts,Part) Parts;

module [TestModule] testCollector(Empty);

	Reg#(Whole) whole  <- mkRegU;
	Reg#(Part)  part   <- mkRegU;
	Reg#(Parts) vector <- mkRegU;
	let numParts = fromInteger(valueof(NumParts));

	Reg#(int) i <- mkRegU;
	Reg#(Bool) correct <- mkReg(True);

	Pipe#(Part,Whole) collectLE <- mkCollectorLE;
	function testCollectLE(x) = (seq
		vector <= toChunks(x);
		for (i<=0;i<numParts;i<=i+1) seq
			collectLE.in.put(vector[i]);
		endseq
		action
			let y <- collectLE.out.get();
			correct <= x == y;
		endaction
		return correct;
	endseq);
	addFuzzTest(10,"CollectLE",testCollectLE);

	Pipe#(Whole,Part) splitLE <- mkSplitterLE;
	function testSplitterLE(x) = seq
		splitLE.in.put(x);
		for (i<=0;i<numParts;i<=i+1) action
			let v <- splitLE.out.get();
			vector[i] <= v;
		endaction
		return vector == toChunks(x);
	endseq;
	addFuzzTest(10,"SplitterLE",testSplitterLE);

	Pipe#(Part,Whole) collectBE <- mkCollectorBE;
	function testCollectBE(x) = (seq
		vector <= toChunks(x);
		for (i<=numParts;i>0;i<=i-1) seq
			collectBE.in.put(vector[i-1]);
		endseq
		action
			let y <- collectBE.out.get();
			correct <= x == y;
		endaction
		return correct;
	endseq);
	addFuzzTest(10,"CollectBE",testCollectBE);

	Pipe#(Whole,Part) splitBE <- mkSplitterBE;
	function testSplitterBE(x) = seq
		splitBE.in.put(x);
		for (i<=numParts;i>0;i<=i-1) action
			let v <- splitBE.out.get();
			vector[i-1] <= v;
		endaction
		return vector == toChunks(x);
	endseq;
	addFuzzTest(10,"SplitterBE",testSplitterBE);

endmodule

module [Module] test(Empty);
	runTests(testCollector);
endmodule

endpackage
