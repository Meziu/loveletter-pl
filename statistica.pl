:- consult(conoscenza).

add_comp(_-N, Acc, NuovoAcc) :-
    NuovoAcc is Acc + N.

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
    foldl(add_comp, Coppie, 0, NStati).

% Restituisce la carta che il Giocatore ha più probabilità di avere in mano. Non deterministico.
mano_piu_probabile(Conoscenza, Giocatore, CartaProbabile) :-
    occorrenze_carta_in_mano(Conoscenza, Giocatore, Coppie, _),
    pairs_keys_values(Coppie, Carte, Counts),
    pairs_keys_values(CoppieSwapped, Counts, Carte),
    max_member(_-CartaProbabile, CoppieSwapped).

% Stampa la probabilità per ogni carta
stampa_probabilita_mano(Conoscenza, Giocatore) :-
    occorrenze_carta_in_mano(Conoscenza, Giocatore, Coppie, Totale),
    forall(member(Carta-Favorevoli, Coppie),
           (
               Prob is Favorevoli / Totale * 100,
               format("  ~w: ~d/~d (~2f%)~n", [Carta, Favorevoli, Totale, Prob])
           )
    ).
