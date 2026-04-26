:- module(possibile, [turno_possibile/3]).

:- use_module('../evento'),
use_module('../stato'),
use_module('../../conoscenza'),
use_module('../../mazzo'),
use_module('../../cardset').

turno_possibile(Conoscenza, Evento, PesoTotale) :-
    giocatore_corrente(Conoscenza, Giocatore),
    informazioni(Conoscenza, Informazioni),
    giocatori(Conoscenza, Giocatori),
    findall(G, member(protetto(G), Informazioni), Protetti),
    aggregate_all(bag(E-P),
                  (   stato_possibile(Conoscenza, Stato, PS),
                      giocata_possibile_stato(Giocatore, Stato, Informazioni, E, PG),
                      controllo_protezione(Giocatore, Giocatori, Protetti, E),
                      P is PS * PG
                  ), Paia),
    msort(Paia, PaiaOrdinati),
    group_pairs_by_key(PaiaOrdinati, Gruppi),
    member(Evento-Pesi, Gruppi),
    sumlist(Pesi, PesoTotale).

controllo_protezione(Giocatore, Giocatori, Protetti, Evento) :-
    % Se TUTTI i giocatori avversari sono protetti, allora non si può bersagliare nessuno e si deve poter usare il fallback
    exclude(=(Giocatore), Giocatori, Avversari),
    (   subset(Avversari, Protetti)
    ->  % tutti protetti, solo eventi senza bersaglio
        \+ bersaglio(_, Evento)
    ;   % altrimenti solo i protetti non sono bersagliabili
        \+ ( member(G, Protetti),
             bersaglio(G, Evento)
           ),
        % evita versione "senza bersaglio" se esiste quella con bersaglio
        (
            usa_carta(Carta, Evento),
            carta_con_bersaglio(Carta) ->
                Evento \= carta_giocata(_, Carta)
        )
    ).

giocata_possibile_stato(Giocatore, Stato, Informazioni, Evento, Peso) :-
    giocatore(Giocatore, Evento),
    mano(Giocatore, CartaInMano, Stato),
    mani(CarteGiocatori, Stato),
    mazzo(Mazzo, Stato),
    carta_rimossa(CartaRimossa, Stato),
    % si gioca la carta già in mano o quella pescata
    (
        CartaGiocata = CartaInMano,
        select(Giocatore-CartaInMano, CarteGiocatori, Tmp),
        CarteGiocatori2 = [Giocatore-CartaPescata  |Tmp]
    ;
        CartaGiocata = CartaPescata,
        CarteGiocatori2 = CarteGiocatori
    ),
    pesca_informata_cardset(CartaPescata, Informazioni, Mazzo, Mazzo2, PesoCartaPescata),
    Stato2 = stato(CarteGiocatori2, Mazzo2, CartaRimossa),
    usa_carta(CartaGiocata, Evento),
    gioco_carta(Giocatore, Informazioni, Stato2, CartaGiocata, Evento, PesoGioco),
    Peso is PesoCartaPescata * PesoGioco.
% TODO: come gestire il caso in cui il giocante o il bersaglio è conoscitivo?

gioco_carta(G, _, _, spia, carta_giocata(G, spia), 1).
gioco_carta(G, _, S, guardia, carta_giocata(G, guardia, Bersaglio, CartaScelta, true), 1) :-
    mani(ManoGiocatori, S),
    member(Bersaglio-CartaInManoBersaglio, ManoGiocatori),
    dif(G, Bersaglio),
    dif(CartaScelta, guardia),
    CartaInManoBersaglio = CartaScelta.
gioco_carta(G, _, S, guardia, carta_giocata(G, guardia, Bersaglio, CartaScelta, false), 1) :-
    mani(ManoGiocatori, S),
    member(Bersaglio-CartaInManoBersaglio, ManoGiocatori),
    carta(CartaScelta),
    dif(G, Bersaglio),
    dif(CartaScelta, guardia),
    dif(CartaInManoBersaglio, CartaScelta).
gioco_carta(G, _, S, prete, carta_giocata(G, prete, Bersaglio, CartaVista), 1) :-
    dif(G, Bersaglio),
    mano(Bersaglio, CartaVista, S).
gioco_carta(G, _, S, barone, carta_giocata(G, barone, Bersaglio), 1) :-
    dif(G, Bersaglio),
    mano(G, CartaG, S),
    mano(Bersaglio, CartaB, S),
    \+ dif(CartaG, CartaB).
gioco_carta(G, _, S, barone, carta_giocata(G, barone, Bersaglio, Eliminato, CartaEliminata), 1) :-
    dif(G, Bersaglio),
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
gioco_carta(G, _, _, domestica, carta_giocata(G, domestica), 1).
gioco_carta(G, _, S, principe, carta_giocata(G, principe, Bersaglio, CartaScartata), 1) :-
    mano(Bersaglio, CartaScartata, S).
gioco_carta(G, I, S, cancelliere, carta_giocata(G, cancelliere, CO1, CO2, CO3), Peso) :-
    mano(G, C1, S),
    mazzo(M1, S),
    pesca_informata_cardset(C2, I, M1, M2, P2), % TODO: RESTITUIRE IL PESO SOMEHOW
    pesca_informata_cardset(C3, I, M2, _M3, P3),
    Peso is P2 * P3,
    permutation([C1, C2, C3], [CO1, CO2, CO3]).
gioco_carta(G, _, S, re, carta_giocata(G, re, Bersaglio, CartaPassata, CartaOttenuta), 1) :-
    dif(G, Bersaglio),
    mano(G, CartaPassata, S),
    mano(Bersaglio, CartaOttenuta, S).
gioco_carta(G, _, S, contessa, carta_giocata(G, contessa), 1) :-
    \+ mano(G, principe, S),
    \+ mano(G, re, S).
gioco_carta(G, _, S, principessa, carta_giocata(G, principessa, CartaEliminata), 1) :-
    mano(G, CartaEliminata, S).
gioco_carta(G, _, _, Carta, carta_giocata(G, Carta), 1) :-
    bersaglio(_, EventoBersaglio),
    usa_carta(Carta, EventoBersaglio).
