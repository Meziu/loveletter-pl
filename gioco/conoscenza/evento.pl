:- module(evento, [reg_evento/3, reg_eventi/3]).

:- use_module(informazione),
use_module('../mazzo'),
use_module('../cardset').

risolvi_uguaglianze(_, _, [], []).
risolvi_uguaglianze(Giocatore, Carta, [CU  |R1], [carta_posseduta(Giocatore2, Carta)  |R2]) :-
    (
        CU = carta_uguale(Giocatore, Giocatore2);
        CU = carta_uguale(Giocatore2, Giocatore)
    ),
    risolvi_uguaglianze(Giocatore, Carta, R1, R2).
risolvi_uguaglianze(Giocatore, Carta, [CU  |R1], [CU  |R2]) :-
    \+ (
           (
               CU = carta_uguale(Giocatore, _);
               CU = carta_uguale(_, Giocatore)
           )
       ),
    risolvi_uguaglianze(Giocatore, Carta, R1, R2).

% Aggiornamento della conoscenza dopo un evento osservato

% Carta scartata nel proprio turno
reg_evento(
           conoscenza(Giocatori, Informazioni, Scarti),
           carta_scartata(Giocatore, Carta),
           conoscenza(Giocatori, NuoveInformazioni, NuoviScarti)) :-
    exclude(riguarda(Giocatore, Carta), Informazioni, NuoveInformazioni),
    aggiungi_a_cardset(Carta, Scarti, NuoviScarti, _).
% Carta scartata nel turno avversario (forzatamente)
reg_evento(
           conoscenza(Giocatori, Info1, Scarti),
           carta_tolta(Giocatore, Carta),
           conoscenza(Giocatori, NuoveInformazioni, NuoviScarti)) :-
    risolvi_uguaglianze(Giocatore, Carta, Info1, Info2),
    exclude(riguarda_giocatore(Giocatore), Info2, NuoveInformazioni),
    aggiungi_a_cardset(Carta, Scarti, NuoviScarti, _).

reg_evento(
           conoscenza(Giocatori, Info1, Scarti),
           carta_vista(Giocatore, Carta),
           conoscenza(Giocatori, NuoveInformazioni, Scarti)) :-
    risolvi_uguaglianze(Giocatore, Carta, Info1, Info2),
    exclude(riguarda_giocatore(Giocatore), Info2, Info3),
    NuoveInformazioni = [carta_posseduta(Giocatore, Carta)  |Info3].

% Giocatore eliminato in un turno diverso dal proprio, quindi aveva 1 carta in mano.
reg_evento(
           conoscenza(Giocatori, Info1, Scarti),
           giocatore_eliminato(Giocatore, CartaScartata),
           CF) :-
    delete(Giocatori, Giocatore, NuoviGiocatori),
    C2 = conoscenza(NuoviGiocatori, Info1, Scarti),
    reg_evento(C2, carta_tolta(Giocatore, CartaScartata), CF).
% Giocatore eliminato nel proprio stesso turno, quindi aveva 2 carte in mano prima di giocare.
reg_evento(
           conoscenza(Giocatori, Info, Scarti),
           giocatore_autoeliminato(Giocatore, CartaScartata),
           CF) :-
    % Non risolviamo le uguaglianze poichè con due carte in mano non siamo certi di quale sia quella uguale.
    delete(Giocatori, Giocatore, NuoviGiocatori),
    exclude(riguarda_giocatore(Giocatore), Info, Info2),
    reg_evento(conoscenza(NuoviGiocatori, Info2, Scarti), carta_scartata(Giocatore, CartaScartata), CF).

% Effetti delle carte
reg_evento(
           C1,
           carta_giocata(Giocatore, spia),
           CF) :-
    !,
    reg_evento(C1, carta_scartata(Giocatore, spia), CF).

reg_evento(C1, carta_giocata(Giocatore, guardia, Bersaglio, CartaScelta, true), CF) :-
    CartaScelta \== guardia,
    reg_evento(C1, carta_scartata(Giocatore, guardia), C2),
    reg_evento(C2, giocatore_eliminato(Bersaglio, CartaScelta), CF).

reg_evento(C1, carta_giocata(Giocatore, guardia, Bersaglio, CartaScelta, false),
           conoscenza(Giocatori, [carta_non_posseduta(Bersaglio, CartaScelta)|I2], Scarti)) :-
    CartaScelta \== guardia,
    reg_evento(C1, carta_scartata(Giocatore, guardia), conoscenza(Giocatori, I2, Scarti)).

% Senza conoscerne la carta
reg_evento(
           C1,
           carta_giocata(Giocatore, prete, _),
           CF) :-
    reg_evento(C1, carta_scartata(Giocatore, prete), CF).
% Conoscendone la carta
reg_evento(
           C1,
           carta_giocata(Giocatore, prete, Bersaglio, CartaVista),
           CF) :-
    reg_evento(C1, carta_giocata(Giocatore, prete, Bersaglio), C2),
    reg_evento(C2, carta_vista(Bersaglio, CartaVista), CF).

reg_evento(
           C1,
           carta_giocata(Giocatore, barone, Bersaglio),
           CF) :-
    reg_evento(C1, carta_scartata(Giocatore, barone), conoscenza(Giocatori, I2, Scarti)),
    CF = conoscenza(Giocatori, [carta_uguale(Giocatore, Bersaglio)  |I2], Scarti).

reg_evento(
           C1,
           carta_giocata(Giocatore, barone, Bersaglio, Eliminato, CartaEliminata),
           CF) :-
    valore(CartaEliminata, V),
    Giocatore \== Bersaglio,
    reg_evento(C1, carta_scartata(Giocatore, barone), C2),
    (
        Giocatore \= Eliminato ->
            Vincitore = Giocatore,
            reg_evento(C2, giocatore_eliminato(Bersaglio, CartaEliminata), conoscenza(Giocatori, I3, Scarti))
    ;
        Bersaglio \= Eliminato ->
            Vincitore = Bersaglio,
            reg_evento(C2, giocatore_autoeliminato(Giocatore, CartaEliminata), conoscenza(Giocatori, I3, Scarti))
    ;
        fail
    ),
    CF = conoscenza(Giocatori, [carta_superiore(Vincitore, V)  |I3], Scarti).

reg_evento(
           C1,
           carta_giocata(Giocatore, domestica),
           CF) :-
    !,
    reg_evento(C1, carta_scartata(Giocatore, domestica), CF).

reg_evento(
           C1,
           carta_giocata(Giocatore, principe, Bersaglio, CartaScartata),
           CF) :-
    reg_evento(C1, carta_scartata(Giocatore, principe), conoscenza(Giocatori, I2, Scarti)),
    (
        Giocatore \== Bersaglio ->
            C3 = conoscenza(Giocatori, [carta_non_posseduta(Giocatore, contessa)  |I2], Scarti),
            % Principessa è l'unica carta con un effetto quando viene scartata.
            (
                CartaScartata == principessa ->
                    reg_evento(C3, giocatore_eliminato(Bersaglio, CartaScartata), CF)
            ;
                reg_evento(C3, carta_tolta(Bersaglio, CartaScartata), CF)
            )
    ;
        C2 = conoscenza(Giocatori, I2, Scarti),
        (
            CartaScartata == principessa ->
                reg_evento(C2, giocatore_autoeliminato(Bersaglio, CartaScartata), CF)
        ;
            reg_evento(C2, carta_scartata(Bersaglio, CartaScartata), CF)
        )
    ).

reg_evento(
           C1,
           carta_giocata(Giocatore, cancelliere, CartaTenuta, CartaPenultima, CartaUltima),
           CF) :-
    reg_evento(C1, carta_giocata(Giocatore, cancelliere), C2),
    reg_evento(C2, carta_vista(Giocatore, CartaTenuta), conoscenza(Giocatori, I3, Scarti)),
    CF = conoscenza(Giocatori, [carta_in_posizione(CartaPenultima, 2), carta_in_posizione(CartaUltima, 1)  |I3], Scarti).

reg_evento(
           C1,
           carta_giocata(Giocatore, cancelliere),
           conoscenza(Giocatori, NuoveInformazioni, Scarti)) :-
    !,
    reg_evento(C1, carta_scartata(Giocatore, cancelliere), conoscenza(Giocatori, I2, Scarti)),
    findall(InfoF,
            (
                member(Info, I2),
                (
                    Info = carta_in_posizione(Carta, Pos) ->
                        NuovoPos is Pos + 2,
                        InfoF = carta_in_posizione(Carta, NuovoPos)
                ;
                    InfoF = Info
                )
            ),
            NuoveInformazioni
    ).

% Senza conoscere le mani scambiate
reg_evento(
           C1,
           carta_giocata(Giocatore, re, Bersaglio),
           conoscenza(Giocatori, NuoveInformazioni, Scarti)) :-
    reg_evento(C1, carta_scartata(Giocatore, re), conoscenza(Giocatori, I2, Scarti)),
    I3 = [carta_non_posseduta(Giocatore, contessa)  |I2],
    % Scambio di giocatore nelle info
    scambia_informazioni(Giocatore, Bersaglio, I3, NuoveInformazioni).
% Conoscendo le mani scambiate
reg_evento(
           C1,
           carta_giocata(Giocatore, re, Bersaglio, CartaPassata, CartaOttenuta),
           conoscenza(Giocatori4, I5, Scarti4)) :-
    reg_evento(C1, carta_scartata(Giocatore, re), C2),
    reg_evento(C2, carta_vista(Giocatore, CartaPassata), C3),
    reg_evento(C3, carta_vista(Bersaglio, CartaOttenuta), conoscenza(Giocatori4, I4, Scarti4)),
    scambia_informazioni(Giocatore, Bersaglio, I4, I5).

reg_evento(
           C1,
           carta_giocata(Giocatore, contessa),
           CF) :-
    !,
    reg_evento(C1, carta_scartata(Giocatore, contessa), CF).

reg_evento(
           C1,
           carta_giocata(Giocatore, principessa, AltraCarta),
           CF) :-
    reg_evento(C1, carta_scartata(Giocatore, principessa), C2),
    reg_evento(C2, giocatore_autoeliminato(Giocatore, AltraCarta), CF).

% Fallback per quando una qualunque carta non può essere attivata
% (e.g. guardia quando tutti gli avversari hanno la domestica attiva).
reg_evento(C1, carta_giocata(Giocatore, Carta), CF) :-
    !,
    reg_evento(C1, carta_scartata(Giocatore, Carta), CF).

% Registrazione ordinata di una lista di eventi
reg_eventi(C, [], C).
reg_eventi(C1, [E  |R], CF) :-
    reg_evento(C1, E, C2),
    reg_eventi(C2, R, CF).
