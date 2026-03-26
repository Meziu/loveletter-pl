% Conta i mondi in cui il giocatore ha una certa carta (in qualsiasi posizione della mano)
probabilita_carta(Carta, Possibilita, Totale, Favorevoli) :-
    length(Possibilita, Totale),
    include([Mano-_]>>(member(Carta, Mano)), Possibilita, MondiConCarta),
    length(MondiConCarta, Favorevoli).

% Stampa la probabilità per ogni carta
stampa_probabilita(Possibilita) :-
    forall(carta(Carta),
        (
            probabilita_carta(Carta, Possibilita, Totale, Favorevoli),
            Favorevoli >= 0,
            Prob is Favorevoli / Totale * 100,
            format("  ~w: ~d/~d (~2f%)~n", [Carta, Favorevoli, Totale, Prob])
        )
    ).
