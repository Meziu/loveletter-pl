:- module(cardset, [aggiorna_copie/4, rimuovi_da_cardset/3, pesca_da_cardset/4, carte_in_cardset/2]).

:- use_module(mazzo),
    use_module('conoscenza/conoscenza'),
    use_module(helpers).

% Cardset lista di coppie carta-conteggio, es: [guardia-3, prete-2, ...]

% Aggiorna il conteggio di una carta nel cardset
aggiorna_copie(Carta, N, [Carta-_  |R], [Carta-N  |R]) :- !.
aggiorna_copie(Carta, N, [H  |R], [H  |NR]) :-
    aggiorna_copie(Carta, N, R, NR).

% Rimuovi una carta dal cardset (decrementa il conteggio)
rimuovi_da_cardset(Carta, Cardset, NuovoCardset) :-
    member(Carta-N, Cardset),
    N > 0,
    N1 is N - 1,
    aggiorna_copie(Carta, N1, Cardset, NuovoCardset).

% Pesca una carta dal cardset (non-deterministico).
% Enumera il numero di copie presenti al momento della pesca.
pesca_da_cardset(Carta, Cardset, NuovoCardset, N) :-
    member(Carta-N, Cardset),
    N > 0,
    rimuovi_da_cardset(Carta, Cardset, NuovoCardset).

carte_in_cardset(Cardset, N) :-
    aggregate_all(
        sum(Copie),
        member(_-Copie, Cardset),
        N
    ).
