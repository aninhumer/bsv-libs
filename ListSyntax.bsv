
package ListSyntax;


import List::*;

export list;


typeclass ListBuilder#(type a, type bldr)
dependencies(bldr determines a);
    function bldr build(List#(a) x);
endtypeclass

instance ListBuilder#(a,List#(a));
    function build = reverse;
endinstance

instance ListBuilder#(a,function bldr f(a x))
provisos(ListBuilder#(a,bldr));
    function build(xs,x) = build(cons(x,xs));
endinstance


function bldr list provisos(ListBuilder#(a,bldr)) = build(Nil);



endpackage