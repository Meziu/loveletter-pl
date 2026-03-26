% =============================================================================
% CONOSCENZA — Vista soggettiva di un giocatore
%
% conoscenza(
%   CarteInMano,       % lista di Nome-Carta per le carte note dei giocatori
%   CartaRimossa,      % 'sconosciuta' oppure una carta specifica
%   Scarti             % lista di carte visibili a tutti
% )
%
% =============================================================================

:- use_module(library(lists)).
:- use_module(library(apply)).

% -----------------------------------------------------------------------------
% Validazione
% -----------------------------------------------------------------------------

conoscenza_valida(conoscenza(CarteInMano, CartaRimossa, Scarti)) :-
    is_list(CarteInMano),
    (CartaRimossa = sconosciuta -> true ; carta(CartaRimossa)),
    lista_di_carte(Scarti).

% -----------------------------------------------------------------------------
% Multiset delle carte libere (non ancora osservate)
%
% Sottraendo dal mazzo completo: mano propria + carte avversari note + scarti
% + carta rimossa (se nota).
% -----------------------------------------------------------------------------

inizializza_multiset(
        conoscenza(CarteInMano, CartaRimossa, Scarti),
        Multiset) :-
    findall(C, member(_-C, CarteInMano), CarteInManoNote),
    append(CarteInManoNote, Scarti, Tmp2),
    (CartaRimossa = sconosciuta
    ->  CarteNote = Tmp2
    ;   append(Tmp2, [CartaRimossa], CarteNote)
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
        conoscenza(CarteInMano, Rimossa, Scarti),
        carta_giocata(Giocatore, Carta),
        conoscenza(NuoveCarteInMano, Rimossa, NuoviScarti)) :-
    rimuovi_primo(Giocatore-Carta, CarteInMano, NuoveCarteInMano),
    append(Scarti, [Carta], NuoviScarti).

aggiorna_conoscenza(
        conoscenza(CarteInMano, Rimossa, Scarti),
        carta_vista(Giocatore, Carta),
        conoscenza(NuoveCarteInMano, Rimossa, Scarti)) :-
    % Aggiunge o sovrascrive la carta nota dell'avversario
    (rimuovi_primo(Giocatore-_, CarteInMano, Tmp)
    ->  true
    ;   Tmp = CarteInMano),
    NuoveCarteInMano = [Giocatore-Carta | Tmp].

aggiorna_conoscenza(
        conoscenza(CarteInMano, Rimossa, Scarti),
        giocatore_eliminato(Giocatore, Carta),
        conoscenza(NuoveCarteInMano, Rimossa, NuoviScarti)) :-
    (rimuovi_primo(Giocatore-_, CarteInMano, NuoveCarteInMano)
    ->  true
    ;   NuoveCarteInMano = CarteInMano),
    append(Scarti, [Carta], NuoviScarti).

% -----------------------------------------------------------------------------
% Analisi probabilistica
%
% Costruisce tutti i mondi possibili compatibili con la conoscenza corrente,
% simulando la sequenza di mosse dentro findall con gioca_carta/pesca_carta.
%
% mondi_possibili(+Conoscenza, +Giocatori, +SimulazioneGoal, -Mondi)
%   SimulazioneGoal è un goal che riceve StatoIn e produce StatoOut,
%   usato per esplorare mosse future prima di interrogare le probabilità.
% -----------------------------------------------------------------------------

% Costruisce la lista di mondi (ManoGiocatore-MultisetRimanente) dopo un'azione di pesca.
pesca_possibile(Conoscenza, Mondi) :-
  inizializza_multiset(Conoscenza, M0),
  findall(Mano-M1,
      (
          pesca_da_multiset(Carta, M0, M1),
          Mano = [Carta]    % pluto ha pescato, mano attuale ignota
      ),
      Mondi
  ).

% probabilita_carta(+Conoscenza, +Giocatore, +Carta, -Prob)
%   Prob è un numero tra 0.0 e 1.0
probabilita_carta(Conoscenza, Giocatore, Carta, Prob) :-
    inizializza_multiset(Conoscenza, Multiset),
    findall(Mano,
        (
            pesca_da_multiset(_, Multiset, _),  % un mondo per ogni carta pescabile
            % La mano del giocatore è la sua carta nota (se presente) + la pescata
            conoscenza(_, _, Avversari, _, _) = Conoscenza,
            (member(Giocatore-CartaNota, Avversari)
            ->  Mano = [CartaNota]
            ;   Mano = [])
        ),
        _MondiGrezzi),
    % Calcolo diretto: quante copie di Carta sono libere rispetto al totale libero
    findall(N, member(_-N, Multiset), Counts),
    sumlist(Counts, Totale),
    (member(Carta-NCarta, Multiset)
    ->  Prob is NCarta / Totale
    ;   Prob is 0.0).

% carta_piu_probabile(+Conoscenza, +Giocatore, -Carta)
%   Restituisce la carta che il Giocatore ha più probabilità di tenere in mano.
%   Se la carta è nota con certezza (da effetto prete), la restituisce direttamente.
carta_piu_probabile(Conoscenza, Giocatore, Carta) :-
    Conoscenza = conoscenza(CarteInMano, _, _),
    (member(Giocatore-Carta, CarteInMano)
    ->  true  % carta già nota con certezza
    ;   inizializza_multiset(Conoscenza, Multiset),
        aggregate_all(max(N, C), member(C-N, Multiset), max(_, Carta))
    ).
