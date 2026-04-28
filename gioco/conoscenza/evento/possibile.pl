:- module(possibile, [turni_possibili/3, turno_possibile/3]).

:- use_module('../evento'),
use_module('../stato'),
use_module('../../conoscenza'),
use_module('../../mazzo'),
use_module('../../cardset').

turni_possibili(Conoscenza, Eventi, PesoTotale) :-
  findall(E-PE, turno_possibile(Conoscenza, E, PE), Eventi),
  aggregate_all(sum(PE), member(_-PE, Eventi), PesoTotale).

turno_possibile(Conoscenza, Evento, PesoTotaleEvento) :-
    giocatore_corrente(Conoscenza, Giocatore),
    informazioni(Conoscenza, Informazioni),
    giocatori(Conoscenza, Giocatori),
    findall(G, member(protetto(G), Informazioni), Protetti),
    exclude(=(Giocatore), Giocatori, Avversari),
    ( subset(Avversari, Protetti)
    -> ModoProtezione = tutti_protetti
    ;  ModoProtezione = parziale(Protetti)
    ),
    aggregate_all(bag(S-PS),
      stato_possibile(Conoscenza, S, PS),
      Stati
    ),
    aggregate_all(bag(CartaUsata-(PS-Stato2-PesoOttenimento)),
            (carta(CartaUsata),
             member(Stato-PS, Stati),
             prepara_stato(Giocatore, CartaUsata, Informazioni, Stato, Stato2, PesoOttenimento)),
            StatiPreparati),
    group_pairs_by_key(StatiPreparati, StatiPerCarta),

    aggregate_all(set(CartaUsata-Evento),
        (member(CartaUsata-StatiCarta, StatiPerCarta),
         member(_-Stato2-_, StatiCarta),
         shape_carta(Giocatore, Stato2, CartaUsata, Evento)),
        Shapes),

    member(CartaUsata-Evento, Shapes),
    check_protezione(ModoProtezione, Evento),
    member(CartaUsata-StatiCarta, StatiPerCarta),
    aggregate_all(sum(PE),
        (member(PS-Stato2-PesoOttenimento, StatiCarta),
         verifica_carta(Giocatore, Informazioni, Stato2, CartaUsata, Evento, PesoGioco),
         PE is PS * (PesoOttenimento + PesoGioco)),
        PesoTotaleEvento),
    PesoTotaleEvento > 0.

check_protezione(tutti_protetti, Evento) :-
    \+ bersaglio(_, Evento).
check_protezione(parziale(Protetti), Evento) :-
    \+ (member(G, Protetti), bersaglio(G, Evento)),
    \+ (Evento = carta_giocata(_, Carta), carta_con_bersaglio(Carta)).

% TODO: come gestire il caso in cui il giocante o il bersaglio è conoscitivo?

% Shared: prepares Stato2 and computes obtaining weight
prepara_stato(Giocatore, CartaUsata, Informazioni, Stato, Stato2, PesoOttenimento) :-
    Stato = stato(CarteGiocatori, Mazzo, CartaRimossa),
    mano(Giocatore, CartaInMano, Stato),
    (
        CartaUsata == CartaInMano ->
            CarteGiocatori2 = CarteGiocatori,
            carte_in_cardset(Mazzo, NMazzo),
            (
                pesca_informata_cardset(CartaUsata, Informazioni, Mazzo, Mazzo2, PesoPesca) ->
                    PesoOttenimento is NMazzo + PesoPesca
                ;
                    Mazzo2 = Mazzo,
                    PesoOttenimento is NMazzo
            )
        ;
            pesca_informata_cardset(CartaUsata, Informazioni, Mazzo, Mazzo2, PesoPesca),
            select(Giocatore-CartaInMano, CarteGiocatori, Tmp),
            CarteGiocatori2 = [Giocatore-CartaUsata|Tmp],
            PesoOttenimento is PesoPesca
    ),
    Stato2 = stato(CarteGiocatori2, Mazzo2, CartaRimossa).

shape_da_stato(Giocatore, CartaUsata, Stato, Informazioni, Evento) :-
    prepara_stato(Giocatore, CartaUsata, Informazioni, Stato, Stato2, _),
    shape_carta(Giocatore, Stato2, CartaUsata, Evento).

peso_da_stato(Giocatore, CartaUsata, Stato, Informazioni, Evento, Peso) :-
    prepara_stato(Giocatore, CartaUsata, Informazioni, Stato, Stato2, PesoOttenimento),
    verifica_carta(Giocatore, Informazioni, Stato2, CartaUsata, Evento, PesoGioco),
    Peso is PesoOttenimento + PesoGioco.

% shape_carta: generates event shape from a specific state, no weights
shape_carta(G, _, spia, carta_giocata(G, spia)).

% Note: guardia false collapses to one event per bersaglio (no CartaScelta)
shape_carta(G, S, guardia, carta_giocata(G, guardia, Bersaglio, CartaScelta, true)) :-
    mani(ManoGiocatori, S),
    member(Bersaglio-CartaScelta, ManoGiocatori),
    G \= Bersaglio, CartaScelta \= guardia.
shape_carta(G, S, guardia, carta_giocata(G, guardia, Bersaglio, false)) :-
    mani(ManoGiocatori, S),
    member(Bersaglio-_, ManoGiocatori),
    G \= Bersaglio.

shape_carta(G, S, prete, carta_giocata(G, prete, Bersaglio, CartaVista)) :-
    mano(Bersaglio, CartaVista, S), G \= Bersaglio.

shape_carta(G, S, barone, carta_giocata(G, barone, Bersaglio)) :-
    mano(G, CartaG, S), mano(Bersaglio, CartaG, S), G \= Bersaglio.
shape_carta(G, S, barone, carta_giocata(G, barone, Bersaglio, Eliminato, CartaEliminata)) :-
    mano(G, CartaG, S), mano(Bersaglio, CartaB, S), G \= Bersaglio,
    valore(CartaG, VG), valore(CartaB, VB),
    (VG > VB -> Eliminato = Bersaglio, CartaEliminata = CartaB
    ; VG < VB -> Eliminato = G,        CartaEliminata = CartaG).

shape_carta(G, _, domestica, carta_giocata(G, domestica)).

shape_carta(G, S, principe, carta_giocata(G, principe, Bersaglio, CartaScartata)) :-
    mano(Bersaglio, CartaScartata, S).

shape_carta(G, _, cancelliere, carta_giocata(G, cancelliere)).

shape_carta(G, S, re, carta_giocata(G, re, Bersaglio, CartaPassata, CartaOttenuta)) :-
    G \= Bersaglio, mano(G, CartaPassata, S), mano(Bersaglio, CartaOttenuta, S).

shape_carta(G, S, contessa, carta_giocata(G, contessa)) :-
    \+ mano(G, principe, S), \+ mano(G, re, S).

shape_carta(G, S, principessa, carta_giocata(G, principessa, CartaEliminata)) :-
    mano(G, CartaEliminata, S).

% verifica_carta: checks ground event against state, returns play weight
verifica_carta(_, _, _, spia, carta_giocata(_, spia), 1).

verifica_carta(_, _, S, guardia, carta_giocata(_, guardia, Bersaglio, CartaScelta, true), 1) :-
    mano(Bersaglio, CartaScelta, S).
verifica_carta(_, _, S, guardia, carta_giocata(_, guardia, Bersaglio, false), Peso) :-
    mano(Bersaglio, CartaB, S),
    aggregate_all(count, (carta(C), C \= guardia, C \= CartaB), Peso).

verifica_carta(_, _, S, prete, carta_giocata(_, prete, Bersaglio, CartaVista), 1) :-
    mano(Bersaglio, CartaVista, S).

verifica_carta(G, _, S, barone, carta_giocata(G, barone, Bersaglio), 1) :-
    mano(G, CartaG, S), mano(Bersaglio, CartaG, S).
verifica_carta(G, _, S, barone, carta_giocata(G, barone, Bersaglio, Eliminato, CartaEliminata), 1) :-
    mano(G, CartaG, S), mano(Bersaglio, CartaB, S),
    valore(CartaG, VG), valore(CartaB, VB),
    (VG > VB -> Eliminato = Bersaglio, CartaEliminata = CartaB
    ; VG < VB -> Eliminato = G,        CartaEliminata = CartaG).

verifica_carta(_, _, _, domestica, carta_giocata(_, domestica), 1).

verifica_carta(_, _, S, principe, carta_giocata(_, principe, Bersaglio, CartaScartata), 1) :-
    mano(Bersaglio, CartaScartata, S).

verifica_carta(G, I, S, cancelliere, carta_giocata(G, cancelliere), Peso) :-
    mazzo(M1, S),
    aggregate_all(sum(P), (
        pesca_informata_cardset(_, I, M1, M2, P2),
        pesca_informata_cardset(_, I, M2, _, P3),
        P is P2 * P3), Peso).

verifica_carta(G, _, S, re, carta_giocata(G, re, Bersaglio, CartaPassata, CartaOttenuta), 1) :-
    mano(G, CartaPassata, S), mano(Bersaglio, CartaOttenuta, S).

verifica_carta(G, _, S, contessa, carta_giocata(G, contessa), 1) :-
    \+ mano(G, principe, S), \+ mano(G, re, S).

verifica_carta(G, _, S, principessa, carta_giocata(G, principessa, CartaEliminata), 1) :-
    mano(G, CartaEliminata, S).
