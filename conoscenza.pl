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

% -----------------------------------------------------------------------------
% Aggiornamento della conoscenza dopo un evento osservato
%
% aggiorna_conoscenza(+Conoscenza, +Evento, -NuovaConoscenza)
%
% Tipi di evento:
%   - carta_scartata(Giocatore, Carta)
%   - carta_vista(Giocatore, Carta)
%   - giocatore_eliminato(Giocatore, Carta)
%     un giocatore esce dal gioco e scarta la sua mano
% -----------------------------------------------------------------------------

aggiorna_conoscenza(
        conoscenza(Giocatori, CarteInMano, Rimossa, Scarti),
        carta_scartata(Giocatore, Carta),
        conoscenza(Giocatori, NuoveCarteInMano, Rimossa, NuoviScarti)) :-
    rimuovi_primo(Giocatore-Carta, CarteInMano, NuoveCarteInMano),
    NuoviScarti = [Carta|Scarti],
    !.

aggiorna_conoscenza(
        conoscenza(Giocatori, CarteInMano, Rimossa, Scarti),
        carta_vista(Giocatore, Carta),
        conoscenza(Giocatori, NuoveCarteInMano, Rimossa, Scarti)) :-
    % Aggiunge o sovrascrive la carta nota dell'avversario
    rimuovi_primo(Giocatore-_, CarteInMano, Tmp),
    NuoveCarteInMano = [Giocatore-Carta | Tmp].

aggiorna_conoscenza(
        conoscenza(Giocatori, CarteInMano, Rimossa, Scarti),
        giocatore_eliminato(Giocatore, CartaScartata),
        conoscenza(NuovoGiocatori, NuoveCarteInMano, Rimossa, NuoviScarti)) :-
    delete(CarteInMano, Giocatore-_, NuoveCarteInMano),
    delete(Giocatori, Giocatore, NuovoGiocatori),
    NuoviScarti = [CartaScartata|Scarti].

% Informazioni sulla mano:
%
% carta_posseduta(Giocatore, Carta) - mutuamente esclusiva alle altre info
% carta_non_posseduta(Giocatore, Carta)
% carta_superiore_a(Giocatore, Valore)
% carta_uguale(Giocatore, Giocatore)

vincoli(G, C, CarteOsservate, CarteInMano) :-
  % Anzichè usare ->, per favorire backtracking si usa una logica inversa.
  % "Non voglio che ci sia una regola E non sia rispettata"
  \+ (
      member(carta_non_posseduta(G, X), CarteOsservate),
      C = X
  ),
  \+ (
      member(carta_superiore(G, Min), CarteOsservate),
      valore(C, V),
      V =< Min
  ),
  \+ (
      (
        member(carta_uguale(G, Altro), CarteOsservate);
        member(carta_uguale(Altro, G), CarteOsservate)
      ),
      member(Altro-CAltro, CarteInMano),
      dif(C, CAltro)
  ).

% Assegna ad ogni giocatore una carta, come nello stato solito di una partita.
mano_giocatori([], _, M, [], _, M).
% con carta nota
mano_giocatori([G|Gs], CarteOsservate, M1, [G-C|R], Acc, MFinale) :-
  member(carta_posseduta(G, C), CarteOsservate),
  rimuovi_primo(carta_posseduta(G, C), CarteOsservate, CarteOsservateRestanti),
  pesca_da_multiset(C, M1, M2),
  mano_giocatori(Gs, CarteOsservateRestanti, M2, R, [G-C|Acc], MFinale).
% senza una carta nota
mano_giocatori([G|Gs], CarteOsservate, M1, [G-C|R], Acc, MFinale) :-
  \+ member(carta_posseduta(G, _), CarteOsservate),
  pesca_da_multiset(C, M1, M2),
  vincoli(G, C, CarteOsservate, Acc),
  mano_giocatori(Gs, CarteOsservate, M2, R, [G-C|Acc], MFinale).

% Stato di gioco possibile data una conoscenza. Non deterministico.
%
% Struttura di uno stato:
% stato([Giocatore-CartaInMano, ...], [CartaNelMazzo-NumeroDiCopie, ...], CartaRimossa)
stato_possibile(C, stato(ManoGiocatori, M2, CartaRimossa)) :-
  C = conoscenza(Giocatori, CarteOsservate, _, _),
  inizializza_multiset(C, M0),
  pesca_da_multiset(CartaRimossa, M0, M1),
  mano_giocatori(Giocatori, CarteOsservate, M1, ManoGiocatori, [], M2).

% Costruisce la lista di stati (ManoGiocatore-MultisetRimanente) dopo un'azione di pesca.
pesca_possibile(Conoscenza, Giocatore, Stati) :-
  Conoscenza = conoscenza(_, CarteInMano, _, _),
  inizializza_multiset(Conoscenza, M),
  pesca_da_multiset(CartaRimossa, M, M0),
  findall(stato(Mano, M2, CartaRimossa),
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
        stato_possibile(Conoscenza, stato(CarteInMano, _, _)),
        member(Giocatore-C, CarteInMano)
      ),
      N
    )
  ), Coppie),
  max_member(Max-_, Coppie),
  member(Max-CartaProbabile, Coppie).
