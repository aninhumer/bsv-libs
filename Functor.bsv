
package Functor;


typeclass Functor#(type f);
    function f#(b) fmap(function b g(a x1), f#(a) xs);
endtypeclass


typeclass Applicative#(type f);
    function f#(a) pointed(a x);
    function f#(b) ap(f#(function b g(a x)) fs, f#(a) xs);
endtypeclass


endpackage