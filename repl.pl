% Stateful REPL con semplici comandi per poter gestire una partita in tempo reale.

:- module(repl, [inizia/1, inizia/2, inizia/3, inizia/4, inizia/5, inizia/6, inizia/1, finisci/0, storia/0, annulla/0, corrente/0, corrente/1, registra/1, rg/1, rg/2, rg/3, rg/4, rv/2, p_mano/1]).

:- use_module('gioco/conoscenza'),
use_module('gioco/conoscenza/evento'),
use_module('gioco/conoscenza/stato'),
use_module(statistica).

:- dynamic storia/1.

% Con lista di giocatori
inizia(Giocatori) :-
    nuova_conoscenza(Giocatori, C),
    conoscenza_valida(C),
    finisci,
    asserta(storia([C])),
    Giocatori = [Primo  |_],
    format("Inizio partita, turno di: ~a~n", [Primo]).

% Con N giocatori
inizia(G1, G2) :-
  inizia([G1, G2]).
inizia(G1, G2, G3) :-
  inizia([G1, G2, G3]).
inizia(G1, G2, G3, G4) :-
  inizia([G1, G2, G3, G4]).
inizia(G1, G2, G3, G4, G5) :-
  inizia([G1, G2, G3, G4, G5]).
inizia(G1, G2, G3, G4, G5, G6) :-
  inizia([G1, G2, G3, G4, G5, G6]).

finisci :-
    retractall(storia(_)).

storia :-
    storia(S),
    writeln(S).

registra(Evento) :-
    storia(S1),
    S1 = [CL  |_],
    once(reg_evento(CL, Evento, C2)),
    (
        % Se si tratta di un evento di gioco del turno
        functor(Evento, carta_giocata, _) ->
            prossimo_turno(C2, CN),
            giocatori(CN, [Prossimo  |_]),
            format("Prossimo turno di: ~a~n", [Prossimo])
    ;
        CN = C2
    ),
    S2 = [CN  |S1],
    retractall(storia(_)),
    asserta(storia(S2)).

% Scorciatoia per registra(carta_giocata(GiocatoreAttuale, ...))
rg(C) :-
    corrente(Con),
    giocatore_corrente(Con, G),
    registra(carta_giocata(G, C)).
rg(C, A1) :-
    corrente(Con),
    giocatore_corrente(Con, G),
    registra(carta_giocata(G, C, A1)).
rg(C, A1, A2) :-
    corrente(Con),
    giocatore_corrente(Con, G),
    registra(carta_giocata(G, C, A1, A2)).
rg(C, A1, A2, A3) :-
    corrente(Con),
    giocatore_corrente(Con, G),
    registra(carta_giocata(G, C, A1, A2, A3)).

% Scorciatoia per registra(carta_vista(...))
rv(G, C) :-
    registra(carta_vista(G, C)).

annulla :-
    storia(S1),
    S1 = [_  |S2],
    retractall(storia(_)),
    asserta(storia(S2)).

corrente(C) :-
    storia([C  |_]).
corrente :-
    corrente(C),
    writeln(C).

p_mano(Giocatore) :-
    corrente(C),
    stampa_probabilita_mano(C, Giocatore).
