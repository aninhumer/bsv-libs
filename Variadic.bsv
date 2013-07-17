
package Variadic;


import List::*;

export list;


typeclass ListBuilder#(type a, type bldr)
dependencies(bldr determines a);
    function bldr listBuild(List#(a) x);
endtypeclass

instance ListBuilder#(a,List#(a));
    function listBuild = List::reverse;
endinstance

instance ListBuilder#(a,function bldr f(a x))
provisos(ListBuilder#(a,bldr));
    function listBuild(xs,x) = listBuild(List::cons(x,xs));
endinstance

function bldr list provisos(ListBuilder#(a,bldr)) =
    listBuild(Nil);


import Vector::*;

export vector;


typeclass VectorBuilder#(type n, type a, type bldr)
dependencies(bldr determines (n,a));
    function bldr vecBuild(Vector#(n,a) x);
endtypeclass

instance VectorBuilder#(n,a,Vector#(n,a));
    function vecBuild = Vector::reverse;
endinstance

instance VectorBuilder#(n,a,function bldr f(a x))
provisos(VectorBuilder#(TAdd#(n,1),a,bldr));
    function vecBuild(xs,x) = vecBuild(Vector::cons(x,xs));
endinstance

function bldr vector provisos(VectorBuilder#(0,a,bldr)) =
    vecBuild(nil);


endpackage
