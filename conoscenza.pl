% =============================================================================
% CONOSCENZA — Vista parziale dello stato di gioco
%
% conoscenza(
%   Giocatori,        % lista dei nomi dei giocatori
%   Informazioni,     % lista di informazioni riguardo alle carte in gioco
%   CartaRimossa,     % 'sconosciuta' oppure una carta specifica
%   Scarti            % lista di carte visibili a tutti
% )
%
% =============================================================================

conoscenza_valida(conoscenza(_, Informazioni, CartaRimossa, Scarti)) :-
    is_list(Informazioni),
    (CartaRimossa = sconosciuta -> true ; carta(CartaRimossa)),
    lista_di_carte(Scarti).

nuova_conoscenza(Giocatori, conoscenza(Giocatori, [], sconosciuta, [])).

% -----------------------------------------------------------------------------
% Multiset delle carte in gioco
%
% Sottraendo dal mazzo completo: pila degli scarti + carta rimossa (se nota).
% -----------------------------------------------------------------------------

inizializza_multiset(
        conoscenza(_, _, CartaRimossa, Scarti), Multiset) :-
    (CartaRimossa = sconosciuta
    ->  CarteNote = Scarti
    ;   CarteNote = [CartaRimossa | Scarti]
    ),
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

riguarda(G, carta_posseduta(G, _)).
riguarda(G, carta_non_posseduta(G, _)).
riguarda(G, carta_superiore(G, _)).
riguarda(G, carta_uguale(G, _)).
riguarda(G, carta_uguale(_, G)).

scambia_giocatore(G1, G2, I, I2) :-
  \+ riguarda(G1, I),
  riguarda(G2, I),
  scambia_giocatore(G2, G1, I, I2).
scambia_giocatore(G1, G2, carta_posseduta(G1, C), carta_posseduta(G2, C)).
scambia_giocatore(G1, G2, carta_non_posseduta(G1, C), carta_non_posseduta(G2, C)).
scambia_giocatore(G1, G2, carta_superiore(G1, V), carta_superiore(G2, V)).
scambia_giocatore(G1, G2, carta_uguale(G1, G2), carta_uguale(G1, G2)) :- !. % caso in cui si scambia tra due giocatori legati
scambia_giocatore(G1, G2, carta_uguale(G1, Gd), carta_uguale(G2, Gd)).
scambia_giocatore(G1, G2, carta_uguale(Gd, G1), carta_uguale(Gd, G2)).
% se le info non appartengono ai giocatori
scambia_giocatore(G1, G2, I, I) :-
    \+ riguarda(G1, I),
    \+ riguarda(G2, I).

scambio_informazioni(G1, G2, InformazioniDaCambiare, NuoveInformazioni) :-
    G1 \== G2,
    findall(I2,
        (
          member(I1, InformazioniDaCambiare),
          scambia_giocatore(G1, G2, I1, I2)
        ),
        NuoveInformazioni
    ).

vincoli(G, C, Informazioni, CarteInMano, PosizioneNelMazzo) :-
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
  \+ (
      member(carta_in_posizione(CartaPos, Pos), Informazioni),
      Pos = PosizioneNelMazzo,
      dif(C, CartaPos)
  ).

% Assegna ad ogni giocatore una carta, come nello stato solito di una partita.
mano_giocatori([], _, M, [], _, M).
% con carta nota
mano_giocatori([G|Gs], Informazioni, M1, [G-C|R], Acc, MFinale) :-
  member(carta_posseduta(G, C), Informazioni),
  rimuovi_primo(carta_posseduta(G, C), Informazioni, InformazioniRestanti),
  pesca_da_multiset(C, M1, M2),
  mano_giocatori(Gs, InformazioniRestanti, M2, R, [G-C|Acc], MFinale).
% senza una carta nota
mano_giocatori([G|Gs], Informazioni, M1, [G-C|R], Acc, MFinale) :-
  \+ member(carta_posseduta(G, _), Informazioni),
  carte_in_multiset(M1, Pos), % numero prima dell'estrazione
  pesca_da_multiset(C, M1, M2),
  vincoli(G, C, Informazioni, Acc, Pos),
  mano_giocatori(Gs, Informazioni, M2, R, [G-C|Acc], MFinale).

% -----------------------------------------------------------------------------
% Aggiornamento della conoscenza dopo un evento osservato
%
% reg_evento(+Conoscenza, +Evento, -NuovaConoscenza)
%
% Tipi di evento:
%   - carta_scartata(Giocatore, Carta)
%   - carta_vista(Giocatore, Carta)
%   - giocatore_eliminato(Giocatore, Carta)
%     un giocatore esce dal gioco e scarta la sua mano
% -----------------------------------------------------------------------------

% Se è nota una relazione di "uguaglianza" con un altro giocatore
reg_evento(
        conoscenza(Giocatori, Informazioni, Rimossa, Scarti),
        carta_scartata(Giocatore, Carta),
        CF) :-
    member(CU, Informazioni),
    (
      CU = carta_uguale(Giocatore, Giocatore2);
      CU = carta_uguale(Giocatore2, Giocatore)
    ),
    !,
    delete(Informazioni, CU, Info2),
    reg_evento(conoscenza(Giocatori, Info2, Rimossa, Scarti), carta_scartata(Giocatore, Carta), C2),
    reg_evento(C2, carta_vista(Giocatore2, Carta), CF).
% Se NON è nota una relazione di "uguaglianza" con un altro giocatore
reg_evento(
        conoscenza(Giocatori, Informazioni, Rimossa, Scarti),
        carta_scartata(Giocatore, Carta),
        conoscenza(Giocatori, NuoveInformazioni, Rimossa, NuoviScarti)) :-
    exclude(riguarda(Giocatore), Informazioni, NuoveInformazioni),
    NuoviScarti = [Carta | Scarti].

reg_evento(
        conoscenza(Giocatori, Informazioni, Rimossa, Scarti),
        carta_vista(Giocatore, Carta),
        conoscenza(Giocatori, NuoveInformazioni, Rimossa, Scarti)) :-
    % Non lavoriamo su "carta_uguale" poiché lo considera il generatore di possibili stati
    exclude(riguarda(Giocatore), Informazioni, Tmp),
    NuoveInformazioni = [carta_posseduta(Giocatore, Carta) | Tmp].

reg_evento(
        conoscenza(Giocatori, Informazioni, Rimossa, Scarti),
        giocatore_eliminato(Giocatore, CartaScartata),
        CF) :-
    delete(Giocatori, Giocatore, NuoviGiocatori),
    C2 = conoscenza(NuoviGiocatori, Informazioni, Rimossa, Scarti),
    reg_evento(C2, carta_scartata(Giocatore, CartaScartata), CF).

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
    reg_evento(C1, carta_scartata(Giocatore, guardia), C2),
    C2 = conoscenza(Giocatori, I2, Rimossa, NuoviScarti),
    (
      IsEliminato == true ->
        reg_evento(C2, giocatore_eliminato(Bersaglio, CartaScelta), CF)
      ;
      IsEliminato == false ->
        CF = conoscenza(Giocatori, [carta_non_posseduta(CartaScelta) | I2], Rimossa, NuoviScarti)
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
    reg_evento(C1, carta_scartata(Giocatore, barone), conoscenza(Giocatori, I2, Rimossa, Scarti)),
    CF = conoscenza(Giocatori, [carta_uguale(Giocatore, Bersaglio) | I2], Rimossa, Scarti).

reg_evento(
        C1,
        carta_giocata(Giocatore, barone, Bersaglio, Eliminato, CartaEliminata),
        CF) :-
    atom(Eliminato),
    valore(CartaEliminata, V),
    Giocatore \== Bersaglio,
    reg_evento(C1, carta_scartata(Giocatore, barone), C2),
    reg_evento(C2, giocatore_eliminato(Eliminato, CartaEliminata), conoscenza(Giocatori, I3, Rimossa, Scarti)),
    (
      Giocatore \= Eliminato ->
        Vincitore = Giocatore
      ;
      Bersaglio \= Eliminato ->
        Vincitore = Bersaglio
      ;
        fail
    ),
    CF = conoscenza(Giocatori, [carta_superiore(Vincitore, V) | I3], Rimossa, Scarti).

reg_evento(
        C1,
        carta_giocata(Giocatore, domestica),
        CF) :-
    reg_evento(C1, carta_scartata(Giocatore, domestica), CF).

reg_evento(
        C1,
        carta_giocata(Giocatore, principe, Bersaglio, CartaScartata),
        CF) :-
    reg_evento(C1, carta_scartata(Giocatore, principe), conoscenza(Giocatori, I2, Rimossa, Scarti)),
    C3 = conoscenza(Giocatori, [carta_non_posseduta(Giocatore, contessa) | I2], Rimossa, Scarti),
    % Principessa è l'unica carta con un effetto quando viene scartata.
    (
      CartaScartata == principessa ->
        reg_evento(C3, giocatore_eliminato(Bersaglio, CartaScartata), CF)
      ;
        reg_evento(C3, carta_scartata(Bersaglio, CartaScartata), CF)
    ).

reg_evento(
        C1,
        carta_giocata(Giocatore, cancelliere, CartaTenuta, CartaPenultima, CartaUltima),
        CF) :-
    reg_evento(C1, carta_giocata(Giocatore, cancelliere), C2),
    reg_evento(C2, carta_vista(Giocatore, CartaTenuta), conoscenza(Giocatori, I3, Rimossa, Scarti)),
    CF = conoscenza(Giocatori, [carta_in_posizione(CartaPenultima, 2), carta_in_posizione(CartaUltima, 1) | I3], Rimossa, Scarti).

reg_evento(
        C1,
        carta_giocata(Giocatore, cancelliere),
        conoscenza(Giocatori, NuoveInformazioni, Rimossa, Scarti)) :-
    reg_evento(C1, carta_scartata(Giocatore, cancelliere), conoscenza(Giocatori, I2, Rimossa, Scarti)),
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


reg_evento(
        C1,
        carta_giocata(Giocatore, re, Bersaglio),
        conoscenza(Giocatori, NuoveInformazioni, Rimossa, Scarti)) :-
    reg_evento(C1, carta_scartata(Giocatore, re), conoscenza(Giocatori, I2, Rimossa, Scarti)),
    I3 = [carta_non_posseduta(Giocatore, contessa) | I2],
    % Scambio di giocatore nelle info
    scambio_informazioni(Giocatore, Bersaglio, I3, NuoveInformazioni).

reg_evento(
        C1,
        carta_giocata(Giocatore, contessa),
        CF) :-
    reg_evento(C1, carta_scartata(Giocatore, contessa), CF).

reg_evento(
        C1,
        carta_giocata(Giocatore, principessa),
        CF) :-
    reg_evento(C1, giocatore_eliminato(Giocatore, principessa), CF).

% Stato di gioco possibile data una conoscenza. Non deterministico.
%
% Struttura di uno stato:
% stato([Giocatore-CartaInMano, ...], [CartaNelMazzo-NumeroDiCopie, ...], CartaRimossa)
stato_possibile(C, stato(ManoGiocatori, M2, CartaRimossa)) :-
  C = conoscenza(Giocatori, Informazioni, _, _),
  inizializza_multiset(C, M0),
  pesca_da_multiset(CartaRimossa, M0, M1),
  mano_giocatori(Giocatori, Informazioni, M1, ManoGiocatori, [], M2).

% Costruisce la lista di stati (ManoGiocatore-MultisetRimanente) dopo un'azione di pesca.
%pesca_possibile(Conoscenza, Giocatore, Stati) :-
%  Conoscenza = conoscenza(_, Informazioni, _, _),
%  inizializza_multiset(Conoscenza, M),
%  pesca_da_multiset(CartaRimossa, M, M0),
%  findall(stato(Mano, M2, CartaRimossa),
%      (
%        member(Giocatore-CartaInMano, Informazioni) ->
%          pesca_da_multiset(Carta, M0, M1),
%          Mano = [CartaInMano, Carta]
%        ;
%          pesca_da_multiset(CartaInMano, M0, M1), % La prima è una "pesca fittizia" per indicare una carta a caso tra le disponibili
%          pesca_da_multiset(Carta, M1, M2),
%          Mano = [CartaInMano, Carta]
%      ),
%      Stati
%  ).

% Restituisce la carta che il Giocatore ha più probabilità di avere in mano. Non deterministico.
carta_piu_probabile(Conoscenza, Giocatore, CartaProbabile) :-
  aggregate_all(bag(N-C), (
    carta(C),
    aggregate_all(count, (
        stato_possibile(Conoscenza, stato(CarteInMano, _, _)),
        member(Giocatore-C, CarteInMano)
      ),
      N
    )
  ), Coppie),
  max_member(Max-_, Coppie),
  member(Max-CartaProbabile, Coppie).
