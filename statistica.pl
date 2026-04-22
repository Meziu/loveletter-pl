:- module(statistica, [occorrenze_carta_in_mano/4, mano_piu_probabile/3, entropia_mano/3, delta_entropia_mano/4, stampa_probabilita_mano/2]).

:- use_module('gioco/conoscenza/conoscenza').

% Restituisce per ogni carta, il numero di possibili stati in cui appare.
occorrenze_carta_in_mano(Conoscenza, Giocatore, Coppie, NStati) :-
    aggregate_all(bag(Carta-Peso), (
                      stato_possibile(Conoscenza, stato(CarteInMano, _, _), Peso),
                      member(Giocatore-Carta, CarteInMano)
                                   ),
                  CarteGiocatore
    ),
    aggregate_all(bag(C-N), (
                      carta(C),
                      aggregate_all(sum(Peso), member(C-Peso, CarteGiocatore), N)
                            ), CoppieGrezze),
    transpose_pairs(CoppieGrezze, CoppieGrezze2),
    reverse(CoppieGrezze2, Coppie),
    pairs_values(CoppieGrezze, Vs),
    foldl(plus, Vs, 0, NStati).

% Restituisce la carta che il Giocatore ha più probabilità di avere in mano. Non deterministico.
mano_piu_probabile(Conoscenza, Giocatore, CartaProbabile) :-
    occorrenze_carta_in_mano(Conoscenza, Giocatore, Coppie, _),
    % la lista è automaticamente ordinata in ordine decrescente, quindi usiamo il primo valore
    Coppie = [Max-_  |_],
    member(Max-CartaProbabile, Coppie).

% All hail Shannon
somma_entropia(_, _-0, Acc, Acc) :- !.
somma_entropia(Totale, _-Favorevoli, Acc, H) :-
    P is Favorevoli / Totale,
    H is Acc - P * log(P) / log(2).

entropia_mano(Conoscenza, Giocatore, Entropia) :-
    occorrenze_carta_in_mano(Conoscenza, Giocatore, Coppie, Totale),
    foldl(somma_entropia(Totale),
          Coppie,
          0,
          Entropia
    ).

delta_entropia_mano(C1, C2, Giocatore, Guadagno) :-
    entropia_mano(C1, Giocatore, E1),
    entropia_mano(C2, Giocatore, E2),
    Guadagno is E1 - E2.

% Stampa la probabilità per ogni carta
stampa_probabilita_mano(Conoscenza, Giocatore) :-
    occorrenze_carta_in_mano(Conoscenza, Giocatore, Coppie, Totale),
    Totale =\= 0,
    forall(member(Favorevoli-Carta, Coppie),
           (
               Prob is Favorevoli / Totale * 100,
               format("  ~w: ~d/~d (~2f%)~n", [Carta, Favorevoli, Totale, Prob])
           )
    ).
