% Vista parziale dello stato di gioco
%
% conoscenza(
%   Giocatori,        % lista dei nomi dei giocatori
%   Informazioni,     % lista di informazioni riguardo alle carte in gioco
%   Scarti            % lista di carte visibili a tutti
% )

:- consult(mazzo).

conoscenza_valida(conoscenza(Giocatori, Informazioni, Scarti)) :-
    length(Giocatori, L),
    L > 0,
    L =< 6,
    is_list(Informazioni),
    lista_di_carte(Scarti).

nuova_conoscenza(Giocatori, conoscenza(Giocatori, [], [])).

stampa_conoscenza(conoscenza(Giocatori, Informazioni, Scarti)) :-
    format("  Giocatori in partita: ~w~n", [Giocatori]),
    format("  Informazioni note: ~w~n", [Informazioni]),
    format("  Scarti: ~w~n", [Scarti]).

% Multiset delle carte in gioco
inizializza_multiset(
                     conoscenza(_, _, Scarti), Multiset) :-
    CarteNote = Scarti,
    findall(Carta-CopieLibere,
            (
                carta(Carta),
                numero_copie(Carta, TotCopie),
                conta(Carta, CarteNote, Usate),
                CopieLibere is TotCopie - Usate,
                CopieLibere >= 0
            ),
            Multiset).

% Informazioni sulla mano:
%
% carta_posseduta(Giocatore, Carta) - mutuamente esclusiva alle altre info
% carta_non_posseduta(Giocatore, Carta)
% carta_superiore(Giocatore, Valore)
% carta_uguale(Giocatore, Giocatore)
% carta_in_posizione(Carta, Posizione) - posizione dal fondo del mazzo

riguarda_carta(C, carta_posseduta(_, C)).
% "riguarda_carta" indica se un informazione è compatibile con una determinata carta.
% Pertanto, il non-possedimento (controintuitivamente) riguarda "tutte le carte che non sono la non-posseduta".
riguarda_carta(C1, carta_non_posseduta(_, C2)) :-
    C1 \= C2.
riguarda_carta(C, carta_superiore(_, V)) :-
    valore(C, Vc),
    Vc >= V.
riguarda_carta(_, carta_uguale(_, _)).

riguarda_giocatore(G, carta_posseduta(G, _)).
riguarda_giocatore(G, carta_non_posseduta(G, _)).
riguarda_giocatore(G, carta_superiore(G, _)).
riguarda_giocatore(G, carta_uguale(G, _)).
riguarda_giocatore(G, carta_uguale(_, G)).

riguarda_giocatore_senza_uguale(G, I) :-
    I \= carta_uguale(_, _),
    riguarda_giocatore(G, I).

riguarda(Giocatore, Carta, I) :-
    riguarda_carta(Carta, I),
    riguarda_giocatore(Giocatore, I).

scambia_giocatore(G1, G2, I, I2) :-
    \+ riguarda_giocatore(G1, I),
    riguarda_giocatore(G2, I),
    scambia_giocatore(G2, G1, I, I2).
scambia_giocatore(G1, G2, carta_posseduta(G1, C), carta_posseduta(G2, C)).
scambia_giocatore(G1, G2, carta_non_posseduta(G1, C), carta_non_posseduta(G2, C)).
scambia_giocatore(G1, G2, carta_superiore(G1, V), carta_superiore(G2, V)).
% caso in cui si scambia tra due giocatori legati
scambia_giocatore(G1, G2, carta_uguale(G1, G2), carta_uguale(G1, G2)).
scambia_giocatore(G1, G2, carta_uguale(G1, Gd), carta_uguale(G2, Gd)) :-
    G2 \= Gd.
scambia_giocatore(G1, G2, carta_uguale(Gd, G1), carta_uguale(Gd, G2)) :-
    G2 \= Gd.

scambio_informazioni(G1, G2, InformazioniDaCambiare, NuoveInformazioni) :-
    G1 \== G2,
    findall(I2,
            (
                member(I1, InformazioniDaCambiare),
                scambia_giocatore(G1, G2, I1, I2)
            ),
            NuoveInformazioni
    ).

vincoli(G, C, Informazioni, CarteInMano, Multiset) :-
    carte_in_multiset(Multiset, PosizioneNelMazzo),
    % Anzichè usare ->, per favorire backtracking si usa una logica inversa.
    % "Non voglio che ci sia una regola E non sia rispettata"
    \+ (
           member(carta_non_posseduta(G, X), Informazioni),
           C = X
       ),
    \+ (
           member(carta_superiore(G, Min), Informazioni),
           valore(C, V),
           V =< Min
       ),
    \+ (
           (
               member(carta_uguale(G, Altro), Informazioni);
               member(carta_uguale(Altro, G), Informazioni)
           ),
           member(Altro-CAltro, CarteInMano),
           dif(C, CAltro)
       ),
    % Controllo di pesca alla posizione esatta
    \+ (
           member(carta_in_posizione(CartaPos, Pos), Informazioni),
           Pos = PosizioneNelMazzo,
           dif(C, CartaPos)
       ),
    % Controllo che non si usino copie extra ad una posizione quando si sa che devono essere in un altra.
    \+ (
           aggregate_all(count,
                         (
                             member(carta_in_posizione(C, PosVincolo), Informazioni),
                             PosVincolo < PosizioneNelMazzo
                         ),
                         N),
           N > 0,
           member(C-Copie, Multiset),
           Copie =< N
       ).

% Assegna ad ogni giocatore una carta, come nello stato solito di una partita.
mano_giocatori([], _, M, [], _, M, 1).
% con carta nota
mano_giocatori([G|Gs], Informazioni, M1, [G-C|R], Acc, MFinale, Peso) :-
    member(carta_posseduta(G, C), Informazioni),
    rimuovi_primo(carta_posseduta(G, C), Informazioni, InformazioniRestanti),
    pesca_da_multiset(C, M1, M2, P1),
    mano_giocatori(Gs, InformazioniRestanti, M2, R, [G-C|Acc], MFinale, P2),
    Peso is P1 * P2.
% senza una carta nota
mano_giocatori([G|Gs], Informazioni, M1, [G-C|R], Acc, MFinale, Peso) :-
    \+ member(carta_posseduta(G, _), Informazioni),
    pesca_da_multiset(C, M1, M2, P1),
    vincoli(G, C, Informazioni, Acc, M1), % multiset considerato *prima* di pescare
    mano_giocatori(Gs, Informazioni, M2, R, [G-C|Acc], MFinale, P2),
    Peso is P1 * P2.

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
    NuoviScarti = [Carta  |Scarti].
% Carta scartata nel turno avversario (forzatamente)
reg_evento(
           conoscenza(Giocatori, Info1, Scarti),
           carta_tolta(Giocatore, Carta),
           conoscenza(Giocatori, NuoveInformazioni, NuoviScarti)) :-
    risolvi_uguaglianze(Giocatore, Carta, Info1, Info2),
    exclude(riguarda_giocatore(Giocatore), Info2, NuoveInformazioni),
    NuoviScarti = [Carta  |Scarti].

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
    reg_evento(C1, carta_scartata(Giocatore, spia), CF).

reg_evento(
           C1,
           carta_giocata(Giocatore, guardia, Bersaglio, CartaScelta, IsEliminato),
           CF) :-
    bool(IsEliminato),
    CartaScelta \== guardia, % Per regolamento, non si può dire "guardia"
    reg_evento(C1, carta_scartata(Giocatore, guardia), C2),
    C2 = conoscenza(Giocatori, I2, NuoviScarti),
    (
        IsEliminato == true ->
            reg_evento(C2, giocatore_eliminato(Bersaglio, CartaScelta), CF)
    ;
        IsEliminato == false ->
            CF = conoscenza(Giocatori, [carta_non_posseduta(Bersaglio, CartaScelta)  |I2], NuoviScarti)
    ;
        fail
    ).

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
    scambio_informazioni(Giocatore, Bersaglio, I3, NuoveInformazioni).
% Conoscendo le mani scambiate
reg_evento(
           C1,
           carta_giocata(Giocatore, re, Bersaglio, CartaPassata, CartaOttenuta),
           CF) :-
    reg_evento(C1, carta_scartata(Giocatore, re), conoscenza(Giocatori2, I2, Scarti2)),
    scambio_informazioni(Giocatore, Bersaglio, I2, I3),
    reg_evento(conoscenza(Giocatori2, I3, Scarti2), carta_vista(Giocatore, CartaOttenuta), C4),
    reg_evento(C4, carta_vista(Bersaglio, CartaPassata), CF).

reg_evento(
           C1,
           carta_giocata(Giocatore, contessa),
           CF) :-
    reg_evento(C1, carta_scartata(Giocatore, contessa), CF).

reg_evento(
           C1,
           carta_giocata(Giocatore, principessa, AltraCarta),
           CF) :-
    reg_evento(C1, carta_scartata(Giocatore, principessa), C2),
    reg_evento(C2, giocatore_autoeliminato(Giocatore, AltraCarta), CF).

% Registrazione ordinata di una lista di eventi
reg_eventi(C, [], C).
reg_eventi(C1, [E  |R], CF) :-
    reg_evento(C1, E, C2),
    reg_eventi(C2, R, CF).

fine_partita(conoscenza([], _, _)).
fine_partita(conoscenza([_], _, _)).
fine_partita(conoscenza(Giocatori, _, Scarti)) :-
  length(Giocatori, LG),
  length(Scarti, LS),
  LS =:= 20 - LG.

% Se rimane un singolo giocatore, ha vinto.
vittoria(conoscenza([Vincitore], _, _), [Vincitore]) :- !.
% Se finiscono le carte, vince quello con carta più alta.
vittoria(Conoscenza, Vincitori) :-
  Conoscenza = conoscenza(Giocatori, Informazioni, _),
  fine_partita(Conoscenza),
  length(Giocatori, LG),
  findall(
    V-G,
    (
      member(carta_posseduta(G, C), Informazioni),
      valore(C, V)
    ),
    PunteggiFinali
  ),
  length(PunteggiFinali, LF),
  LF =:= LG,
  sort(1, @>=, PunteggiFinali, Classifica),
  group_pairs_by_key(Classifica, GruppiDiPunteggio),
  GruppiDiPunteggio = [_-Vincitori | _].

% Stato di gioco possibile data una conoscenza. Non deterministico.
%
% Struttura di uno stato:
% stato([Giocatore-CartaInMano, ...], [CartaNelMazzo-NumeroDiCopie, ...], CartaRimossa)
stato_possibile(C, stato(ManoGiocatori, M2, CartaRimossa), Peso) :-
    C = conoscenza(Giocatori, Informazioni, _),
    inizializza_multiset(C, M0),
    pesca_da_multiset(CartaRimossa, M0, M1, P1),
    mano_giocatori(Giocatori, Informazioni, M1, ManoGiocatori, [], M2, P2),
    Peso is P1 * P2.
