% Vista parziale dello stato di gioco
%
% conoscenza(
%   Giocatori,        % lista dei nomi dei giocatori
%   Informazioni,     % lista di informazioni riguardo alle carte in gioco
%   Scarti            % lista di carte visibili a tutti
% )

:- module(conoscenza, [conoscenza_valida/1, nuova_conoscenza/2, giocatori/2, informazioni/2, scarti/2, stampa_conoscenza/1, fine_partita/1]).

:- use_module('../mazzo'),
  use_module('../cardset'),
  use_module('../helpers').

conoscenza_valida(conoscenza(Giocatori, Informazioni, Scarti)) :-
    length(Giocatori, L),
    between(1, 6, L),
    is_list(Informazioni),
    is_lista_carte(Scarti).

nuova_conoscenza(Giocatori, conoscenza(Giocatori, [], [])).

giocatori(conoscenza(G, _, _), G).
informazioni(conoscenza(_, I, _), I).
scarti(conoscenza(_, _, S), S).

stampa_conoscenza(conoscenza(Giocatori, Informazioni, Scarti)) :-
    format("  Giocatori in partita: ~w~n", [Giocatori]),
    format("  Informazioni note: ~w~n", [Informazioni]),
    format("  Scarti: ~w~n", [Scarti]).

fine_partita(conoscenza([], _, _)).
fine_partita(conoscenza([_], _, _)).
fine_partita(conoscenza(Giocatori, _, Scarti)) :-
    length(Giocatori, LG),
    length(Scarti, LS),
    LS =:= 20 - LG.

% TODO: modifica (in "punteggio"?) per ottenere il punteggio (conteggio con le spie)
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
    GruppiDiPunteggio = [_-Vincitori  |_].
