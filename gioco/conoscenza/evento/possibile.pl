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
    exclude(=(Giocatore), Giocatori, Avversari),
    ( subset(Avversari, Protetti)
    -> ModoProtezione = tutti_protetti
    ;  ModoProtezione = parziale(Protetti)
    ),
    aggregate(
        sum(P),
        Stato^PS^PG^(
                        stato_possibile(Conoscenza, Stato, PS),
                        giocata_possibile_stato(Giocatore, Stato, Informazioni, Evento, PG),
                        check_protezione(ModoProtezione, Evento),
                        P is PS * PG
                    ),
        PesoTotale
    ).

check_protezione(tutti_protetti, Evento) :-
    \+ bersaglio(_, Evento).
check_protezione(parziale(Protetti), Evento) :-
    \+ (member(G, Protetti), bersaglio(G, Evento)),
    \+ (Evento = carta_giocata(_, Carta), carta_con_bersaglio(Carta)).

giocata_possibile_stato(Giocatore, Stato, Informazioni, Evento, Peso) :-
    giocatore(Giocatore, Evento),
    mano(Giocatore, CartaInMano, Stato),
    mani(CarteGiocatori, Stato),
    mazzo(Mazzo, Stato),
    carta_rimossa(CartaRimossa, Stato),
    (
        CartaGiocata = CartaInMano,
        usa_carta(CartaGiocata, Evento),        % filtra PRIMA di pescare
        select(Giocatore-CartaInMano, CarteGiocatori, Tmp),
        pesca_informata_cardset(CartaPescata, Informazioni, Mazzo, Mazzo2, PesoCartaPescata),
        CarteGiocatori2 = [Giocatore-CartaPescata|Tmp]
    ;
        pesca_informata_cardset(CartaPescata, Informazioni, Mazzo, Mazzo2, PesoCartaPescata),
        CartaGiocata = CartaPescata,
        usa_carta(CartaGiocata, Evento),        % qui non si può anticipare ulteriormente
        CarteGiocatori2 = CarteGiocatori
    ),
    Stato2 = stato(CarteGiocatori2, Mazzo2, CartaRimossa),
    gioco_carta(Giocatore, Informazioni, Stato2, CartaGiocata, Evento, PesoGioco),
    Peso is PesoCartaPescata * PesoGioco.
% TODO: come gestire il caso in cui il giocante o il bersaglio è conoscitivo?

gioco_carta(G, _, _, spia, carta_giocata(G, spia), 1).
gioco_carta(G, _, S, guardia, carta_giocata(G, guardia, Bersaglio, CartaScelta, true), 1) :-
    mani(ManoGiocatori, S),
    member(Bersaglio-CartaInManoBersaglio, ManoGiocatori),
    G \= Bersaglio,
    CartaScelta \= guardia,
    CartaInManoBersaglio = CartaScelta.
gioco_carta(G, _, S, guardia, carta_giocata(G, guardia, Bersaglio, CartaScelta, false), 1) :-
    mani(ManoGiocatori, S),
    member(Bersaglio-CartaInManoBersaglio, ManoGiocatori),
    G \= Bersaglio,
    carta(CartaScelta),
    CartaScelta \= guardia,
    CartaInManoBersaglio \= CartaScelta.
gioco_carta(G, _, S, prete, carta_giocata(G, prete, Bersaglio, CartaVista), 1) :-
    G \= Bersaglio,
    mano(Bersaglio, CartaVista, S).
gioco_carta(G, _, S, barone, carta_giocata(G, barone, Bersaglio), 1) :-
    G \= Bersaglio,
    mano(G, CartaG, S),
    mano(Bersaglio, CartaG, S).
gioco_carta(G, _, S, barone, carta_giocata(G, barone, Bersaglio, Eliminato, CartaEliminata), 1) :-
    G \= Bersaglio,
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
% Non generiamo tutte le alternative, ma ne consideriamo il peso
gioco_carta(G, I, S, cancelliere, carta_giocata(G, cancelliere), Peso) :-
    mano(G, _C1, S),
    mazzo(M1, S),
    aggregate_all(sum(P), (
                      pesca_informata_cardset(_C2, I, M1, M2, P2),
                      pesca_informata_cardset(_C3, I, M2, _M3, P3),
                      P is P2 * P3),
                  Peso
    ).
gioco_carta(G, _, S, re, carta_giocata(G, re, Bersaglio, CartaPassata, CartaOttenuta), 1) :-
    G \= Bersaglio,
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
