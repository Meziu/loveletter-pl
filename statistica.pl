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

% Stampa la probabilità per ogni carta
stampa_probabilita_mano(Conoscenza, Giocatore) :-
    occorrenze_carta_in_mano(Conoscenza, Giocatore, Coppie, Totale),
    forall(member(Carta-Favorevoli, Coppie),
           (
               Prob is Favorevoli / Totale * 100,
               format("  ~w: ~d/~d (~2f%)~n", [Carta, Favorevoli, Totale, Prob])
           )
    ).
