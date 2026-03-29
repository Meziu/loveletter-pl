% =============================================================================
% CONOSCENZA — Vista parziale dello stato di gioco
%
% conoscenza(
%   Giocatori,        % lista dei nomi dei giocatori
%   CarteOsservate,   % lista di Nome-Carta per le carte note dei giocatori
%   CartaRimossa,     % 'sconosciuta' oppure una carta specifica
%   Scarti            % lista di carte visibili a tutti
% )
%
% =============================================================================

% -----------------------------------------------------------------------------
% Validazione
% -----------------------------------------------------------------------------

conoscenza_valida(conoscenza(_, CarteInMano, CartaRimossa, Scarti)) :-
    is_list(CarteInMano),
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
    ;   append(Scarti, [CartaRimossa], CarteNote)
    ),
    findall(Carta-CopieLibere,
        (
            carta(Carta),
            numero_copie(Carta, TotCopie),
            conta(Carta, CarteNote, Usate),
            CopieLibere is TotCopie - Usate,
            CopieLibere > 0
        ),
        Multiset).

% -----------------------------------------------------------------------------
% Aggiornamento della conoscenza dopo un evento osservato
%
% aggiorna_conoscenza(+Conoscenza, +Evento, -NuovaConoscenza)
%
% Tipi di evento:
%   carta_giocata(Giocatore, Carta)
%     — un giocatore ha giocato una carta (va negli scarti)
%   carta_vista(Giocatore, Carta)
%     — hai visto la carta di un avversario (es. effetto prete)
%   giocatore_eliminato(Giocatore, Carta)
%     — un giocatore è uscito e ha scartato la sua carta
% -----------------------------------------------------------------------------

aggiorna_conoscenza(
        conoscenza(Giocatori, CarteInMano, Rimossa, Scarti),
        carta_giocata(Giocatore, Carta),
        conoscenza(Giocatori, NuoveCarteInMano, Rimossa, NuoviScarti)) :-
    rimuovi_primo(Giocatore-Carta, CarteInMano, NuoveCarteInMano),
    NuoviScarti = [Carta|Scarti],
    !.

aggiorna_conoscenza(
        conoscenza(Giocatori, CarteInMano, Rimossa, Scarti),
        carta_vista(Giocatore, Carta),
        conoscenza(Giocatori, NuoveCarteInMano, Rimossa, Scarti)) :-
    % Aggiunge o sovrascrive la carta nota dell'avversario
    (rimuovi_primo(Giocatore-_, CarteInMano, Tmp)
    ->  true
    ;   Tmp = CarteInMano),
    NuoveCarteInMano = [Giocatore-Carta | Tmp].

aggiorna_conoscenza(
        conoscenza(Giocatori, CarteInMano, Rimossa, Scarti),
        giocatore_eliminato(Giocatore, Carta),
        conoscenza(Giocatori, NuoveCarteInMano, Rimossa, NuoviScarti)) :-
    (rimuovi_primo(Giocatore-_, CarteInMano, NuoveCarteInMano)
    ->  true
    ;   NuoveCarteInMano = CarteInMano),
    append(Scarti, [Carta], NuoviScarti).

% Assegna ad ogni giocatore una carta, come nello stato solito di una partita.
mano_giocatori([], _, M, [], M).
% con carta osservata
mano_giocatori([G|Gs], CarteOsservate, M1, [G-C|R], MFinale) :-
    member(G-C, CarteOsservate),
    rimuovi_primo(G-C, CarteOsservate, CarteOsservateRestanti),
    pesca_da_multiset(C, M1, M2),
    mano_giocatori(Gs, CarteOsservateRestanti, M2, R, MFinale).
% senza alcuna carta osservata
mano_giocatori([G|Gs], CarteOsservate, M1, [G-C|R], MFinale) :-
    \+ member(G-_, CarteOsservate),
    pesca_da_multiset(C, M1, M2),
    mano_giocatori(Gs, CarteOsservate, M2, R, MFinale).

% Stato di gioco possibile data una conoscenza. Non deterministico.
%
% Struttura di uno stato:
% [Giocatore-CartaInMano, ...]-[CartaNelMazzoORimossa-NumeroDiCopie, ...]
stato_possibile(C, ManoGiocatori-M2) :-
  C = conoscenza(Giocatori, CarteOsservate, _, _),
  inizializza_multiset(C, M1),
  mano_giocatori(Giocatori, CarteOsservate, M1, ManoGiocatori, M2).

% Costruisce la lista di stati (ManoGiocatore-MultisetRimanente) dopo un'azione di pesca.
pesca_possibile(Conoscenza, Giocatore, Stati) :-
  Conoscenza = conoscenza(_, CarteInMano, _, _),
  inizializza_multiset(Conoscenza, M0),
  findall(Mano-M2,
      (
        member(Giocatore-CartaInMano, CarteInMano) ->
          pesca_da_multiset(Carta, M0, M1),
          Mano = [CartaInMano, Carta]
        ;
          pesca_da_multiset(CartaInMano, M0, M1), % La prima è una "pesca fittizia" per indicare una carta a caso tra le disponibili
          pesca_da_multiset(Carta, M1, M2),
          Mano = [CartaInMano, Carta]
      ),
      Stati
  ).

% Restituisce la carta che il Giocatore ha più probabilità di avere in mano. Non deterministico.
carta_piu_probabile(Conoscenza, Giocatore, CartaProbabile) :-
  aggregate_all(bag(N-C), (
    carta(C),
    aggregate_all(count, (
        stato_possibile(Conoscenza, CarteInMano-_),
        member(Giocatore-C, CarteInMano)
      ),
      N
    )
  ), Coppie),
  max_member(Max-_, Coppie),
  member(Max-CartaProbabile, Coppie).
