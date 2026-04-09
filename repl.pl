% Stateful REPL con semplici comandi per poter gestire una partita in tempo reale.

:- consult(conoscenza),
consult(statistica).
:- dynamic storia/1.

inizia(Giocatori) :-
    length(Giocatori, L),
    L > 1,
    finisci,
    nuova_conoscenza(Giocatori, C),
    asserta(storia([C])).

finisci :-
    retractall(storia(_)).

storia :-
    storia(S),
    writeln(S).

registra(Evento) :-
    storia(S1),
    S1 = [CL  |_],
    once(reg_evento(CL, Evento, CN)),
    S2 = [CN  |S1],
    retractall(storia(_)),
    asserta(storia(S2)).

% Scorciatoia per registra(carta_giocata(...))
rg(G, C) :-
    registra(carta_giocata(G, C)).
rg(G, C, A1) :-
    registra(carta_giocata(G, C, A1)).
rg(G, C, A1, A2) :-
    registra(carta_giocata(G, C, A1, A2)).
rg(G, C, A1, A2, A3) :-
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
