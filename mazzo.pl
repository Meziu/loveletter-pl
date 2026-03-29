% =============================================================================
% MAZZO — Definizione carte e operazioni sul multiset
% =============================================================================

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

% Conta le occorrenze di un elemento in una lista
conta(_, [], 0).
conta(X, [X|T], N) :- !, conta(X, T, N1), N is N1 + 1.
conta(X, [_|T], N) :- conta(X, T, N).

% =============================================================================
% MULTISET: lista di coppie carta-conteggio, es: [guardia-3, prete-2, ...]
% =============================================================================

% Aggiorna il conteggio di una carta nel multiset
aggiorna_copie(Carta, N, [Carta-_ | R], [Carta-N | R]) :- !.
aggiorna_copie(Carta, N, [H | R],       [H | NR]) :-
    aggiorna_copie(Carta, N, R, NR).

% Rimuove la prima apparizione di un elemento in una lista.
rimuovi_primo(_, [], []).
rimuovi_primo(X, [X|T], T) :- !.
rimuovi_primo(X, [H|T], [H|R]) :-
    rimuovi_primo(X, T, R).

% Rimuovi una carta dal multiset (decrementa il conteggio, elimina se 0)
rimuovi_da_multiset(Carta, Multiset, NuovoMultiset) :-
    member(Carta-N, Multiset),
    N > 0,
    N1 is N - 1,
    (
        N1 =:= 0
    ->  rimuovi_primo(Carta-N, Multiset, NuovoMultiset)
    ;   aggiorna_copie(Carta, N1, Multiset, NuovoMultiset)
    ).

% Pesca una carta dal multiset (non-deterministico).
% Backtracking enumera tutte le carte possibili,
% una volta per ogni copia ancora disponibile nel multiset.
pesca_da_multiset(Carta, Multiset, NuovoMultiset) :-
    member(Carta-N, Multiset),
    N > 0,
    between(1, N, _),
    rimuovi_da_multiset(Carta, Multiset, NuovoMultiset).
