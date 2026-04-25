:- module(valido, [turno_possibile/2]).

:- use_module('../evento'),
use_module('../stato'),
use_module('../../conoscenza'),
use_module('../../mazzo'),
use_module('../../cardset').

turno_possibile(Conoscenza, Evento) :-
    giocatore_corrente(Conoscenza, Giocatore),
    controllo_protezione(Conoscenza, Evento),
    % TODO: è più efficiente valutare prima lo stato o le giocate?
    stato_possibile(Conoscenza, Stato),
    giocata_possibile_stato(Giocatore, Stato, Evento).

controllo_protezione(Conoscenza, Evento) :-
    informazioni(Conoscenza, Informazioni),
    % Se i giocatori avversari sono protetti, allora non si possono bersagliare.
    forall(member(protetto(G), Informazioni), \+ bersaglio(G, Evento)).
% TODO: aggiungere clausola di sblocco a carte con bersaglio quando tutti i player sono protetti

giocata_possibile_stato(Giocatore, Stato, Evento) :-
    giocatore(Giocatore, Evento),
    mano(Giocatore, CartaInMano, Stato),
    mani(CarteGiocatori, Stato),
    mazzo(Mazzo, Stato),
    carta_rimossa(CartaRimossa, Stato),
    rimuovi_da_cardset(CartaPescata, Mazzo, Mazzo2, PesoCartaPescata),
    % si gioca la carta già in mano o quella pescata
    (
        CartaGiocata = CartaInMano,
        carte_in_cardset(Mazzo, _PesoCartaGiocata) % utilizzabile in ogni caso di pesca
    ;
        CartaGiocata = CartaPescata,
        _PesoCartaGiocata = PesoCartaPescata % utilizzabile solo in N casi di pesca
    ),
    % TODO: RISOLVERE IL CASO IN CUI SI GIOCA LA CARTA CHE ERA GIÀ IN MANO E LA MANO DEL GIOCATORE DEVE DIVENTARE LA CARTA PESCATA
    Stato2 = stato(CarteGiocatori, Mazzo2, CartaRimossa),
    usa_carta(CartaGiocata, Evento),
    gioco_carta(Giocatore, Stato2, CartaGiocata, Evento).
% TODO: come gestire il caso in cui il giocante o il bersaglio è conoscitivo?

gioco_carta(G, _, spia, carta_giocata(G, spia)).
gioco_carta(G, S, guardia, carta_giocata(G, guardia, Bersaglio, CartaScelta, true)) :-
    dif(CartaScelta, guardia),
    mano(Bersaglio, CartaScelta, S).
gioco_carta(G, S, guardia, carta_giocata(G, guardia, Bersaglio, CartaScelta, false)) :-
    dif(CartaScelta, guardia),
    \+ mano(Bersaglio, CartaScelta, S).
gioco_carta(G, S, prete, carta_giocata(G, prete, Bersaglio, CartaVista)) :-
    mano(Bersaglio, CartaVista, S).
gioco_carta(G, S, barone, carta_giocata(G, barone, Bersaglio)) :-
    mano(G, CartaG, S),
    mano(Bersaglio, CartaB, S),
    \+ dif(CartaG, CartaB).
gioco_carta(G, S, barone, carta_giocata(G, barone, Bersaglio, Eliminato, CartaEliminata)) :-
    mano(G, CartaG, S),
    mano(Bersaglio, CartaB, S),
    valore(CartaG, VG),
    valore(CartaB, VB),
    (
        VG > VB,
        Eliminato = Bersaglio,
        CartaEliminata = CartaB
    ;
        VG < VB,
        Eliminato = G,
        CartaEliminata = CartaG
    ).
gioco_carta(G, _, domestica, carta_giocata(G, domestica)).
gioco_carta(G, S, principe, carta_giocata(G, principe, Bersaglio, CartaScartata)) :-
    mano(Bersaglio, CartaScartata, S).
gioco_carta(G, S, cancelliere, carta_giocata(G, cancelliere, CO1, CO2, CO3)) :-
    mano(G, C1, S),
    mazzo(M1, S),
    rimuovi_da_cardset(C2, M1, M2, _), % TODO: RESTITUIRE IL PESO SOMEHOW
    rimuovi_da_cardset(C3, M2, _M3, _), % TODO: ESISTE IL VINCOLO DI PESCA SULLA POSIZIONE A CAUSA DI UN ALTRO CANCELLIERE, AAGHHH
    permutation([C1, C2, C3], [CO1, CO2, CO3]).
gioco_carta(G, S, re, carta_giocata(G, re, Bersaglio, CartaPassata, CartaOttenuta)) :-
    mano(G, CartaPassata, S),
    mano(Bersaglio, CartaOttenuta, S).
gioco_carta(G, S, contessa, carta_giocata(G, contessa)) :-
    \+ mano(G, principe, S),
    \+ mano(G, re, S).
gioco_carta(G, S, principessa, carta_giocata(G, principessa, CartaEliminata)) :-
    mano(G, CartaEliminata, S).
gioco_carta(G, _, Carta, carta_giocata(G, Carta)).
