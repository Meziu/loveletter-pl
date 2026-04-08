% Stateful REPL con semplici comandi per poter gestire una partita in tempo reale.

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
  S1 = [CL | _],
  once(reg_evento(CL, Evento, CN)),
  S2 = [CN | S1],
  retractall(storia(_)),
  asserta(storia(S2)).

annulla :-
  storia(S1),
  S1 = [_ | Cs],
  S2 = [Cs],
  retractall(storia(_)),
  asserta(storia(S2)).

corrente(C) :-
  storia([C | _]).
corrente :-
  corrente(C),
  writeln(C).

p_mano(Giocatore) :-
  corrente(C),
  stampa_probabilita_mano(C, Giocatore).
