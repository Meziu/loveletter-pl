% =============================================================================
% STATISTICA — Aggregazione e stampa probabilità su una lista di mondi
%
% Un "mondo" è un termine ManoGiocatore-MultisetRimanente.
% Questa lista è prodotta da mondi_possibili/5 in conoscenza.pl.
% =============================================================================

% Conta i mondi in cui il giocatore ha una certa carta
conteggio_mondi_carta(Carta, Mondi, Totale, Favorevoli) :-
    length(Mondi, Totale),
    include([Mano-_]>>(member(Carta, Mano)), Mondi, MondiConCarta),
    length(MondiConCarta, Favorevoli).

% Stampa la probabilità per ogni carta
stampa_probabilita(Mondi) :-
    forall(carta(Carta),
        (
            conteggio_mondi_carta(Carta, Mondi, Totale, Favorevoli),
            Prob is Favorevoli / Totale * 100,
            format("  ~w: ~d/~d (~2f%)~n", [Carta, Favorevoli, Totale, Prob])
        )
    ).
