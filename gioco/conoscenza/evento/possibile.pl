:- module(possibile, [turno_possibile/2]).

:- use_module('../evento'),
use_module('../stato'),
use_module('../../conoscenza'),
use_module('../../mazzo'),
use_module('../../cardset').

turno_possibile(Conoscenza, Evento) :-
    giocatore_corrente(Conoscenza, Giocatore),
    controllo_protezione(Conoscenza, Evento),
    informazioni(Conoscenza, Informazioni),
    stato_possibile(Conoscenza, Stato, _Peso),
    giocata_possibile_stato(Giocatore, Stato, Informazioni, Evento).

controllo_protezione(Conoscenza, Evento) :-
    informazioni(Conoscenza, Informazioni),
    giocatori(Conoscenza, Giocatori),
    giocatore_corrente(Conoscenza, Giocatore),
    % Se TUTTI i giocatori avversari sono protetti, allora non si può bersagliare nessuno e si deve poter usare il fallback
    forall((
               dif(G, Giocatore),
               member(G, Giocatori)
           ), member(protetto(G), Informazioni)),
    !, % Non si lascia come possibilità la versione normale di protezione
    \+ bersaglio(_, Evento).
controllo_protezione(Conoscenza, Evento) :-
    informazioni(Conoscenza, Informazioni),
    % I giocatori avversari protetti non si possono bersagliare.
    forall(member(protetto(G), Informazioni), \+ bersaglio(G, Evento)),
    % e non si può usare l'evento di gioco carta generico per le carte che richiedono un bersaglio
    forall(bersaglio(_, EventoBersaglio), (
               usa_carta(CartaConBersaglio, EventoBersaglio),
               dif(Evento, carta_giocata(_, CartaConBersaglio))
                                          )).

giocata_possibile_stato(Giocatore, Stato, Informazioni, Evento) :-
    giocatore(Giocatore, Evento),
    mano(Giocatore, CartaInMano, Stato),
    mani(CarteGiocatori, Stato),
    mazzo(Mazzo, Stato),
    carta_rimossa(CartaRimossa, Stato),
    % si gioca la carta già in mano o quella pescata
    (
        CartaGiocata = CartaInMano,
        carte_in_cardset(Mazzo, _PesoCartaGiocata), % utilizzabile in ogni caso di pesca
        select(Giocatore-CartaInMano, CarteGiocatori, Tmp),
        CarteGiocatori2 = [Giocatore-CartaPescata  |Tmp]
    ;
        CartaGiocata = CartaPescata,
        _PesoCartaGiocata = PesoCartaPescata, % utilizzabile solo in N casi di pesca
        CarteGiocatori2 = CarteGiocatori
    ),
    pesca_informata_cardset(CartaPescata, Informazioni, Mazzo, Mazzo2, PesoCartaPescata),
    Stato2 = stato(CarteGiocatori2, Mazzo2, CartaRimossa),
    usa_carta(CartaGiocata, Evento),
    gioco_carta(Giocatore, Informazioni, Stato2, CartaGiocata, Evento).
% TODO: come gestire il caso in cui il giocante o il bersaglio è conoscitivo?

gioco_carta(G, _, _, spia, carta_giocata(G, spia)).
gioco_carta(G, _, S, guardia, carta_giocata(G, guardia, Bersaglio, CartaScelta, true)) :-
    mani(ManoGiocatori, S),
    member(Bersaglio-CartaInManoBersaglio, ManoGiocatori),
    dif(G, Bersaglio),
    dif(CartaScelta, guardia),
    CartaInManoBersaglio = CartaScelta.
gioco_carta(G, _, S, guardia, carta_giocata(G, guardia, Bersaglio, CartaScelta, false)) :-
    mani(ManoGiocatori, S),
    member(Bersaglio-CartaInManoBersaglio, ManoGiocatori),
    carta(CartaScelta),
    dif(G, Bersaglio),
    dif(CartaScelta, guardia),
    dif(CartaInManoBersaglio, CartaScelta).
gioco_carta(G, _, S, prete, carta_giocata(G, prete, Bersaglio, CartaVista)) :-
    dif(G, Bersaglio),
    mano(Bersaglio, CartaVista, S).
gioco_carta(G, _, S, barone, carta_giocata(G, barone, Bersaglio)) :-
    dif(G, Bersaglio),
    mano(G, CartaG, S),
    mano(Bersaglio, CartaB, S),
    \+ dif(CartaG, CartaB).
gioco_carta(G, _, S, barone, carta_giocata(G, barone, Bersaglio, Eliminato, CartaEliminata)) :-
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
gioco_carta(G, _, _, domestica, carta_giocata(G, domestica)).
gioco_carta(G, _, S, principe, carta_giocata(G, principe, Bersaglio, CartaScartata)) :-
    mano(Bersaglio, CartaScartata, S).
gioco_carta(G, I, S, cancelliere, carta_giocata(G, cancelliere, CO1, CO2, CO3)) :-
    mano(G, C1, S),
    mazzo(M1, S),
    pesca_informata_cardset(C2, I, M1, M2, _), % TODO: RESTITUIRE IL PESO SOMEHOW
    pesca_informata_cardset(C3, I, M2, _M3, _),
    permutation([C1, C2, C3], [CO1, CO2, CO3]).
gioco_carta(G, S, re, carta_giocata(G, re, Bersaglio, CartaPassata, CartaOttenuta)) :-
    dif(G, Bersaglio),
    mano(G, CartaPassata, S),
    mano(Bersaglio, CartaOttenuta, S).
gioco_carta(G, S, contessa, carta_giocata(G, contessa)) :-
    \+ mano(G, principe, S),
    \+ mano(G, re, S).
gioco_carta(G, S, principessa, carta_giocata(G, principessa, CartaEliminata)) :-
    mano(G, CartaEliminata, S).
gioco_carta(G, _, Carta, carta_giocata(G, Carta)) :-
    bersaglio(_, EventoBersaglio),
    usa_carta(Carta, EventoBersaglio).
