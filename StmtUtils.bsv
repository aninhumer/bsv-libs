/*****************************************************************************
StmtUtils
=========
Alex Horsman, Sept 2012

This library provides several functions intended to simplify the creation of
Stmts by replacing common patterns.

*****************************************************************************/

import GetPut::*;
import Vector::*;
import Monad::*;
import StmtFSM::*;

import Pipes::*;
import RegUtils::*;

//These functions wrap up the two common ways ActionValues are
//used in Stmts: Discarding or storing the result.

//Perform an ActionValue and discard the result.
function Action dropAV(ActionValue#(a) av) = action
	let _ <- av;
endaction;

//Perform an ActionValue and store the result in a register.
function Action storeAV(ActionValue#(a) av, Reg#(a) r) = action
	let v <- av;
	r <= v;
endaction;


//The following functions are for use with Sources and Sinks as
//defined in the Pipes library. This provides a uniform way to
//write common actions involving FIFOs, Servers etc.

//Transfer one value from a Source to a Sink.
function Action transferData(srcT src, snkT snk)
	provisos(Sink#(snkT,dataT),Source#(srcT,dataT)) =
	action
		let v <- sourceToGet(src).get();
		sinkToPut(snk).put(v);
	endaction;

//Put one value into a Sink.
function Action putData(snkT s, dataT x) provisos(Sink#(snkT,dataT)) = action
	sinkToPut(s).put(x);
endaction;

//Take one value out of a Source into a register.
function Action getData(srcT s, Reg#(dataT) r)
	provisos(Source#(srcT,dataT),Bits#(dataT,n)) =
	storeAV(sourceToGet(s).get(),r);


//The following functions generate sequences of the above actions
//involving Sources and Sinks, for when a transfer cannot be
//completed in one action.

//Warning!: These functions generate unrolled sequences of actions
//rather than for loops. This means the resulting FSM can be very
//large and involve many rules, and this in turn can cause long
//compile times.
//If a module using one of these functions takes longer than
//expected to compile, it is suggested to replace these functions
//with explict loops.

//Turns an Action into a Stmt.
//This is useful for use with higher level functions.
function RStmt#(_) toStmt(Action a) = seq a; endseq;

//Stream a large value as several smaller ones into a Sink
//in Little Endian order.
function RStmt#(_) putStreamLE(snkT s, wholeT w) provisos(
	Sink#(snkT,partT),Bits#(partT,pSize),
	Bits#(wholeT,wSize),Mul#(n,pSize,wSize));
	return mapM_(toStmt,map(putData(s),toChunks(w)));
endfunction

//As above, but in Big Endian order.
function RStmt#(_) putStreamBE(snkT s, wholeT w) provisos(
	Sink#(snkT,partT),Bits#(partT,pSize),
	Bits#(wholeT,wSize),Mul#(n,pSize,wSize));
	return mapM_(toStmt,map(putData(s),reverse(toChunks(w))));
endfunction

//Stream a series of smaller values into a larger register
//in Little Endian order.
function RStmt#(_) getStreamLE(srcT s, Reg#(wholeT) w) provisos(
	Source#(srcT,partT),Bits#(partT,pSize),
	Bits#(wholeT,wSize),Mul#(n,pSize,wSize));
	return mapM_(toStmt,map(getData(s),splitReg(w)));
endfunction

//As above, but in Big Endian order.
function RStmt#(_) getStreamBE(srcT s, Reg#(wholeT) w) provisos(
	Source#(srcT,partT),Bits#(partT,pSize),
	Bits#(wholeT,wSize),Mul#(n,pSize,wSize));
	return mapM_(toStmt,map(getData(s),reverse(splitReg(w))));
endfunction

