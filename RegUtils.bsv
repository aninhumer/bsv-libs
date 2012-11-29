/*****************************************************************************
RegUtils
========
Alex Horsman, Sept 2012

This library provides several functions and modules intended to make using
registers easier.

The function shadowReg takes a register of one type, and returns a register
interface of another type which refers to the same state. This replaces the
pattern of using unpack(pack()) on all accesses, and also improves type safety
since accesses to the new interface must still be the correct type. The two
types must both implement Bits of the same size.

The module mkShadowReg wraps shadowReg in a module.

The function splitReg takes a register of any type and returns a Vector of
register interfaces corresponding to parts of the register's state. The width
of the register must divide evenly into the Vector. Note that the resulting
register interfaces still perform full reads and writes to access the larger
register, so they cannot be used in parallel.

*****************************************************************************/

package RegUtils;

import Vector::*;


function Reg#(outT) shadowReg(Reg#(inT) r)
	provisos(Bits#(inT,n),Bits#(outT,n)) =
	interface Reg;
		method Action _write(outT x) = r._write(unpack(pack(x)));
		method outT _read() = unpack(pack(r._read()));
	endinterface;

module mkShadowReg#(Reg#(inT) r)(Reg#(outT))
	provisos(Bits#(inT,n),Bits#(outT,n));

	return shadowReg(r);
endmodule


function Vector#(n,Reg#(partT)) splitReg(Reg#(wholeT) r) provisos(
	Bits#(wholeT,wholeSize),Bits#(partT,partSize),
	Mul#(partSize,n,wholeSize));

	Reg#(Vector#(n,partT)) parts = shadowReg(r);
	function subReg(i) = interface Reg;
		method Action _write(partT x);
			parts[i] <= x;
		endmethod
		method _read() = parts[i];
	endinterface;
	return genWith(subReg);
endfunction

endpackage
