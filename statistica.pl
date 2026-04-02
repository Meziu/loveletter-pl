% =============================================================================
% STATISTICA — Aggregazione e stampa probabilità su una lista di stati
% =============================================================================

% Conta gli stato in cui il giocatore ha una certa carta
conteggio_stati_carta(Carta, Stati, Totale, Favorevoli) :-
    length(Stati, Totale),
    include([stato(Mano, _, _)]>>(member(Carta, Mano)), Stati, StatiConCarta),
    length(StatiConCarta, Favorevoli).

% Stampa la probabilità per ogni carta
stampa_probabilita(Stati) :-
    forall(carta(Carta),
           (
               conteggio_stati_carta(Carta, Stati, Totale, Favorevoli),
               Prob is Favorevoli / Totale * 100,
               format("  ~w: ~d/~d (~2f%)~n", [Carta, Favorevoli, Totale, Prob])
           )
    ).
