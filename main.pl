:- consult(mazzo),
consult(statistica),
consult(conoscenza),
initialization(main).

main :-
    write('=== ANALISI: probabilità mano di pippo dopo il gioco di 2 cancellieri ==='), nl,
    C4 = conoscenza([pippo, pluto], [carta_uguale(pippo, pluto), carta_non_posseduta(pippo, principessa)], sconosciuta, []),
    reg_eventi(C4, [carta_giocata(pippo, guardia, pluto, principessa, false), carta_giocata(pluto, cancelliere, re, barone, prete), carta_giocata(pippo, cancelliere)], C5),
    stampa_probabilita_mano(C5, pippo).
