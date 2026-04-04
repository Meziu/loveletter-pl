:- consult(mazzo),
consult(statistica),
consult(conoscenza),
initialization(main).

main :-
    write('=== ANALISI: probabilità mano di pippo dopo il gioco di 2 cancellieri ==='), nl,
    C1 = conoscenza([pippo, pluto], [carta_uguale(pippo, pluto), carta_non_posseduta(pippo, principessa)], sconosciuta, []),
    reg_eventi(C1, [carta_giocata(pluto, cancelliere, re, barone, prete), carta_giocata(pippo, cancelliere)], C2),
    stampa_probabilita_mano(C2, pippo).
