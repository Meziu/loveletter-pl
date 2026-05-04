:- module(simulazione, [conoscenza_in_depth/3]).

:- use_module(conoscenza),
  use_module('conoscenza/evento').

conoscenza_in_depth(C, 0, C) :- !.
conoscenza_in_depth(C, _, _) :-
  fine_partita(C),
  !,
  fail.
conoscenza_in_depth(C1, D1, CF) :-
  D2 is D1 - 1,
  turno_possibile(C1, EP, PEP),
  reg_evento(C1, EP, C2),
  conoscenza_in_depth(C2, D2, CF).
