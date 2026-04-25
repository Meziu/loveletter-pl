:- module(cardset, [cardset/1, cardset_pieno/1, cardset_vuoto/1, cardset_complemento/2, rimuovi_da_cardset/4, aggiungi_a_cardset/4, carta_presente/2, copie_carta/3, carte_in_cardset/2]).

:- use_module(mazzo).

% Cardset lista di coppie carta-conteggio, es: [spia-1, guardia-3, prete-2, ...]

cardset(Cardset) :-
    findall(Carta, carta(Carta), Carte),
    maplist(range_carta, Carte, Cardset).
range_carta(Carta, Carta-Copie) :-
    numero_copie(Carta, Max),
    between(0, Max, Copie).

cardset_pieno(Cardset) :-
    findall(Carta, carta(Carta), Carte),
    maplist(max_carta, Carte, Cardset).
max_carta(Carta, Carta-Max) :-
    numero_copie(Carta, Max).

cardset_vuoto(Cardset) :-
    findall(Carta, carta(Carta), Carte),
    maplist(no_carta, Carte, Cardset).
no_carta(Carta, Carta-0).

cardset_complemento(Cardset, Complemento) :-
    maplist(complementare, Cardset, Complemento).
complementare(Carta-N1, Carta-N2) :-
    numero_copie(Carta, C),
    between(0, C, N1),
    N2 is C - N1.

% Rimuove una carta dal cardset.
% Restituisce il numero di copie presenti prima della rimozione.
rimuovi_da_cardset(Carta, [Carta-N1  |R], [Carta-N2  |R], N1) :-
    N1 > 0,
    N2 is N1 - 1.
rimuovi_da_cardset(Carta, [H  |R], [H  |NR], NC) :-
    rimuovi_da_cardset(Carta, R, NR, NC).

% Aggiunge una carta al cardset.
% Restituisce il numero di copie presenti dopo l'aggiunta.
aggiungi_a_cardset(Carta, [Carta-N1  |R], [Carta-N2  |R], N2) :-
    numero_copie(Carta, Max),
    N2 is N1 + 1,
    N2 =< Max.
aggiungi_a_cardset(Carta, [H  |R], [H  |NR], NC) :-
    aggiungi_a_cardset(Carta, R, NR, NC).

% Vero se è presente almeno una copia della carta nel cardset.
carta_presente(Carta, Cardset) :-
    member(Carta-N, Cardset),
    N > 0.

% Vero se è presente almeno una copia della carta nel cardset.
copie_carta(Carta, Cardset, N) :-
    member(Carta-N, Cardset).

carte_in_cardset(Cardset, N) :-
    aggregate_all(
        sum(Copie),
        member(_-Copie, Cardset),
        N
    ).
