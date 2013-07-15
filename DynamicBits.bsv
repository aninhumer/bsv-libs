
package DynamicBits;


import List::*;


typedef List#(Bit#(1)) DynamicBits;

function DynamicBits toDynamic (dataT x)
provisos (Bits#(dataT,dataWidth));
    if (valueof(dataWidth) == 0) begin
        return Nil;
    end else begin
        return Cons {
            _1: pack(x)[0],
            _2: toDynamic(Bit#(TSub#(dataWidth,1))'(truncateLSB(pack(x))))
        };
    end
endfunction


function dataT fromDynamic(DynamicBits dyn)
provisos(Bits#(dataT,dataWidth));
    if (valueof(dataWidth) == 0) begin
        return ?;
    end else begin
        case (dyn) matches
            tagged Nil :
                return error("Not enough dynamic bits.");
            tagged Cons { _1: .x, _2: .xs } :
                return unpack(
                    { Bit#(TSub#(dataWidth,1))'(fromDynamic(xs)), x }
                );
        endcase
    end
endfunction


endpackage