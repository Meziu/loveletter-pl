% =============================================================================
% MAIN — Punto di ingresso per una partita reale dal punto di vista di un giocatore
%
% Carica tutti i moduli e dimostra il flusso completo:
%   1. Inizializzazione della conoscenza a inizio round
%   2. Aggiornamento dopo eventi osservati
%   3. Interrogazione probabilistica
%
% =============================================================================

:- initialization(main).

main :-
    consult(mazzo),
    consult(statistica),
    consult(conoscenza),

    % -------------------------------------------------------------------------
    % Stato iniziale: pippo ha in mano guardia e spia.
    % Sai che pluto ha il barone (da un effetto prete precedente).
    % Paperino è già eliminato.
    % Negli scarti: prete, guardia, spia, guardia.
    % Non sai quale carta è stata rimossa a inizio round.
    % -------------------------------------------------------------------------

    Scarti = [prete, guardia, spia, guardia],

    C0 = conoscenza(
        [pippo-guardia, pippo-spia, pluto-barone],     % sai dalla carta prete che pluto ha il barone
        sconosciuta,
        Scarti
    ),

    nl, write('=== STATO INIZIALE ==='), nl,
    stampa_conoscenza(C0),

    % -------------------------------------------------------------------------
    % Evento 1: pippo gioca la spia
    % -------------------------------------------------------------------------

    aggiorna_conoscenza(C0, carta_giocata(pippo, spia), C1),

    nl, write('=== DOPO: pippo gioca la spia ==='), nl,
    stampa_conoscenza(C1),

    % -------------------------------------------------------------------------
    % Evento 2: pluto gioca il barone (la carta nota viene scartata)
    % -------------------------------------------------------------------------

    aggiorna_conoscenza(C1, carta_giocata(pluto, barone), C2),

    nl, write('=== DOPO: pluto gioca il barone ==='), nl,
    stampa_conoscenza(C2),

    % -------------------------------------------------------------------------
    % Evento 3: pluto pesca.
    % -------------------------------------------------------------------------

    nl, write('=== ANALISI: probabilità mano di pluto ==='), nl,
    pesca_possibile(C2, pluto, Mondi),
    stampa_probabilita(Mondi),

    carta_piu_probabile(C2, pluto, CartaConsigliata),
    nl, format("Carta consigliata da indovinare con la guardia: ~w~n", [CartaConsigliata]),

    % -------------------------------------------------------------------------
    % Evento 4: si scopre che pluto aveva la principessa (è uscito).
    % -------------------------------------------------------------------------

    aggiorna_conoscenza(C2, giocatore_eliminato(pluto, principessa), C3),

    nl, write('=== DOPO: pluto eliminato con principessa ==='), nl,
    stampa_conoscenza(C3).

% -----------------------------------------------------------------------------
% Stampa la conoscenza corrente
% -----------------------------------------------------------------------------

stampa_conoscenza(conoscenza(Avversari, CartaRimossa, Scarti)) :-
    format("  Carte in mano note: ~w~n", [Avversari]),
    format("  Carta rimossa: ~w~n", [CartaRimossa]),
    format("  Scarti: ~w~n", [Scarti]).
