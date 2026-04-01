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
% carta_superiore_a(Giocatore, Valore)
% carta_uguale(Giocatore, Giocatore)

info(G, carta_posseduta(G, _)).
info(G, carta_non_posseduta(G, _)).
info(G, carta_superiore_a(G, _)).
info(G, carta_uguale(G, _)).
info(G, carta_uguale(_, G)).

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
% aggiorna_conoscenza(+Conoscenza, +Evento, -NuovaConoscenza)
%
% Tipi di evento:
%   - carta_scartata(Giocatore, Carta)
%   - carta_vista(Giocatore, Carta)
%   - giocatore_eliminato(Giocatore, Carta)
%     un giocatore esce dal gioco e scarta la sua mano
% -----------------------------------------------------------------------------

aggiorna_conoscenza(
        conoscenza(Giocatori, Informazioni, Rimossa, Scarti),
        carta_scartata(Giocatore, Carta),
        conoscenza(Giocatori, NuoveInformazioni, Rimossa, NuoviScarti)) :-
    rimuovi_primo(Giocatore-Carta, Informazioni, NuoveInformazioni),
    NuoviScarti = [Carta | Scarti].

aggiorna_conoscenza(
        conoscenza(Giocatori, Informazioni, Rimossa, Scarti),
        carta_vista(Giocatore, Carta),
        conoscenza(Giocatori, NuoveInformazioni, Rimossa, Scarti)) :-
    % Aggiunge o sovrascrive la carta nota dell'avversario
    delete(info(Giocatore, _), Informazioni, Tmp),
    NuoveInformazioni = [carta_posseduta(Giocatore, Carta) | Tmp].

aggiorna_conoscenza(
        conoscenza(Giocatori, Informazioni, Rimossa, Scarti),
        giocatore_eliminato(Giocatore, CartaScartata),
        conoscenza(NuovoGiocatori, NuoveInformazioni, Rimossa, NuoviScarti)) :-
    delete(Informazioni, Giocatore-_, NuoveInformazioni),
    delete(Giocatori, Giocatore, NuovoGiocatori),
    NuoviScarti = [CartaScartata | Scarti].

% Effetti delle carte


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
