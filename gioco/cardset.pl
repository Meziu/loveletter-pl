:- module(cardset, [cardset/1, rimuovi_da_cardset/4, carte_in_cardset/2]).

% Cardset lista di coppie carta-conteggio, es: [guardia-3, prete-2, ...]

cardset(C) :-
    forall(C, member(Carta-Copie, C), (carta(Carta), Copie > 0)).

% Rimuove una carta dal cardset.
% Restituisce il numero di copie presenti prima della rimozione.
rimuovi_da_cardset(Carta, [Carta-N1  |R], [Carta-N2  |R], N1) :-
    !,
    N1 > 0,
    N2 is N1 - 1.
rimuovi_da_cardset(Carta, [H  |R], [H  |NR], NC) :-
    rimuovi_da_cardset(Carta, R, NR, NC).

carte_in_cardset(Cardset, N) :-
    aggregate_all(
        sum(Copie),
        member(_-Copie, Cardset),
        N
    ).
