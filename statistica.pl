:- consult(conoscenza).

% Restituisce per ogni carta, il numero di possibili stati in cui appare
occorrenze_carta_in_mano(Conoscenza, Giocatore, Coppie, NStati) :-
    aggregate_all(bag(C-N), (
                      carta(C),
                      aggregate_all(count, (
                                        stato_possibile(Conoscenza, stato(CarteInMano, _, _)),
                                        member(Giocatore-C, CarteInMano)
                                           ),
                                    N
                      )
                            ), Coppie),
    pairs_values(Coppie, Cs),
    foldl(plus, Cs, 0, NStati).

% Restituisce la carta che il Giocatore ha più probabilità di avere in mano. Non deterministico.
mano_piu_probabile(Conoscenza, Giocatore, CartaProbabile) :-
    occorrenze_carta_in_mano(Conoscenza, Giocatore, Coppie, _),
    transpose_pairs(Coppie, Traspos),
    % la trasposizione è automaticamente ordinata in ordine crescente, quindi usiamo l'ultimo valore
    last(Traspos, Max-_),
    member(Max-CartaProbabile, Traspos).

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
    forall(member(Carta-Favorevoli, Coppie),
           (
               Prob is Favorevoli / Totale * 100,
               format("  ~w: ~d/~d (~2f%)~n", [Carta, Favorevoli, Totale, Prob])
           )
    ).
