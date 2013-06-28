/*****************************************************************************
Testing
=======
Alex Horsman, Sept 2012

This library provides modules to help with implementing test suites. It
provides a special module type TestModule, which uses ModuleCollect to
store a series of tests, and then run them all in sequence, reporting the
results. A test is an RStmt returning a Bool, indicating
whether the test passed. Tests are added with the module addTest, and the
tests within a TestModule can be run using runTests.

The general usage pattern is:

	//Some module definition.
	module mkMyMod(MyModIfc);
		...
	endmodule

	//TestModule for MyMod.
	module [TestModule] testMyMod(Empty);
		//Necessary state definitions, presumably including
		//at least one instance of MyMod.
		addTest("Test 1 name",seq
			...
			return <result>;
		endseq);
		...
		addTest("Test N name,...);
	endmodule

	//Synthesizable module to run the above TestModule.
	module [Module] testRunner(Empty);
		runTests(testMyMod);
	endmodule

This library also allows randomised tests, using addFuzzTest. This module
takes a function returning a test as an argument, and a number of random
tests to run.

Warning!: This module creates large unrolled FSMs to implement various
features and as a result, can take a long time to compile.

*****************************************************************************/

import List::*;
import StmtFSM::*;
import ModuleCollect::*;

import StmtUtils::*;

typedef RStmt#(Bool) TestStmt;

typedef Tuple2#(String,TestStmt) NamedTest;

typedef ModuleCollect#(NamedTest) TestModule;

module [TestModule] addTest#(String name, TestStmt test)(Empty);
	addToCollection(tuple2(name,test));
endmodule

module [Module] runTests#(TestModule#(Empty) tm)(Empty);

	let {_, tests} <- getCollection(tm);

	Reg#(Bool) passed    <- mkRegU;
	Reg#(int)  failCount <- mkReg(0);

	module foldTest#(Stmt acc, NamedTest nt)(Stmt);
		let {name,test} = nt;
		function stalled(trigger) = seq
			await(trigger);
			test;
		endseq;
		FSMServer#(Bool,Bool) fsm <- mkFSMServer(stalled);
		return seq
			acc;
			$write("Running test \"%s\"... ",name);
			passed <- callServer(fsm,True);
			if (passed) seq
				$display("Passed");
			endseq else seq
				$display("FAILED");
				failCount <= failCount + 1;
			endseq
		endseq;
	endmodule

	Stmt testSequence <- foldlM(foldTest,seq endseq,tests);

	mkAutoFSM(seq
		$display("Starting tests");
		testSequence;
		if (failCount == 0)
			$display("All tests passed");
		else
			$display("%d tests failed!",failCount);
	endseq);

endmodule

import Randomizable::*;

typedef (function TestStmt f(a x)) InputTest#(type a);

module [TestModule] addFuzzTest#(Integer times, String name, InputTest#(a) test)(Empty)
	provisos(Bits#(a,_),Eq#(a),Bounded#(a));

	Randomize#(a) random <- mkGenericRandomizer;
	Reg#(a) in  <- mkRegU;

	FSMServer#(a,Bool) testSeq <- mkFSMServer(test);
	
	Reg#(Bool) passed <- mkRegU;
	addTest(name,seq
		random.cntrl.init();
		repeat(fromInteger(times)) seq
			storeAV(random.next(),in);
			passed <- callServer(testSeq,in);
			if (!passed) break;
		endseq
		return passed;
	endseq);

endmodule


module [TestModule] testTesting(Empty);
	addTest("Should Pass",seq return True; endseq);
	addTest("Should Fail",seq return False; endseq);

	function TestStmt f(bit x) = (seq return True; endseq);
	addFuzzTest(10,"Should Pass",f);

	function TestStmt g(bit x) = (seq return False; endseq);
	addFuzzTest(10,"Should Fail",g);
endmodule

module [Module] test(Empty);
	runTests(testTesting);
endmodule
