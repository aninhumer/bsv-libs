
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
    vecBuild(Vector::nil);


import ListN::*;

export listN;


typeclass ListNBuilder#(type n, type a, type bldr)
dependencies(bldr determines (n,a));
    function bldr listNBuild(ListN#(n,a) x);
endtypeclass

instance ListNBuilder#(n,a,ListN#(n,a));
    function listNBuild = ListN::reverse;
endinstance

instance ListNBuilder#(n,a,function bldr f(a x))
provisos(ListNBuilder#(TAdd#(n,1),a,bldr));
    function listNBuild(xs,x) = listNBuild(ListN::cons(x,xs));
endinstance

function bldr listN provisos(ListNBuilder#(0,a,bldr)) =
    listNBuild(ListN::nil);


import HList::*;

export hList;


typeclass HReverse#(type as, type bs)
dependencies(as determines bs);
    function bs hReverse(as x);
endtypeclass

instance HReverse#(HNil,HNil);
    function hReverse = id;
endinstance

instance HReverse#(HCons#(a,as),cs)
provisos(HReverse#(as,bs),HAppend#(bs,HList1#(a),cs));
    function hReverse(xs) = hAppend(hReverse(xs.tl),hList1(xs.hd));
endinstance


typeclass HListBuilder#(type current, type bldr)
dependencies(bldr determines current);
    function bldr hListBuild(current x);
endtypeclass

instance HListBuilder#(as, bs)
provisos(HReverse#(as,bs));
    function hListBuild = hReverse;
endinstance

instance HListBuilder#(as, function bldr f(a x))
provisos(HListBuilder#(bs,bldr),HAppend#(as,HList1#(a),bs));
    function hListBuild(xs,x) = hListBuild(hCons(x,xs));
endinstance

function bldr hList provisos(HListBuilder#(HNil,bldr)) =
    hListBuild(HNil{});


endpackage
