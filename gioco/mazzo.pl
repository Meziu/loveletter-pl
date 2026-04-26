:- module(mazzo, [carta/1, valore/2, numero_copie/2, carta_con_bersaglio/1]).

% Definizione delle carte
carta(spia).
carta(guardia).
carta(prete).
carta(barone).
carta(domestica).
carta(principe).
carta(cancelliere).
carta(re).
carta(contessa).
carta(principessa).

% Valore numerico di ogni carta
valore(spia, 0).
valore(guardia, 1).
valore(prete, 2).
valore(barone, 3).
valore(domestica, 4).
valore(principe, 5).
valore(cancelliere, 6).
valore(re, 7).
valore(contessa, 8).
valore(principessa, 9).

% Numero di copie totali per ogni carta
numero_copie(guardia, 6) :- !.
numero_copie(re, 1) :- !.
numero_copie(contessa, 1) :- !.
numero_copie(principessa, 1) :- !.
numero_copie(Carta, 2) :-
    carta(Carta),
    !.

carta_con_bersaglio(guardia).
carta_con_bersaglio(prete).
carta_con_bersaglio(barone).
carta_con_bersaglio(principe).
carta_con_bersaglio(re).
