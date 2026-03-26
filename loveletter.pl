% Definizione delle carte
carta(spia).
carta(guardia).
carta(prete).
carta(barone).
carta(domestica).
carta(principe).
carta(cancelliere).
carta(re).
carta(contessa).
carta(principessa).

% Valore numerico di ogni carta
valore(spia, 0).
valore(guardia, 1).
valore(prete, 2).
valore(barone, 3).
valore(domestica, 4).
valore(principe, 5).
valore(cancelliere, 6).
valore(re, 7).
valore(contessa, 8).
valore(principessa, 9).

% Numero di copie totali per ogni carta
numero_copie(guardia, 6) :- !.
numero_copie(re, 1) :- !.
numero_copie(contessa, 1) :- !.
numero_copie(principessa, 1) :- !.
numero_copie(Carta, 2) :-
  carta(Carta),
  !.

% Se si tratta di una lista di carte
lista_di_carte([H | R]) :-
  carta(H),
  lista_di_carte(R),
  !.
lista_di_carte([L]) :-
  carta(L),
  !.
lista_di_carte([]).

% Possibili stati di un giocatore.
stato_giocatore(dentro).
stato_giocatore(fuori).

% Verifica di un giocatore
giocatore_valido(giocatore(Nome, Mano, Stato)) :-
  giocatore_valido(Nome, Mano, Stato).
giocatore_valido(
  Nome,
  Mano, % lista di zero, una o due carte, a seconda del turno e stato
  Stato % Se il giocatore è in gioco o meno
) :-
  atom(Nome),
  lista_di_carte(Mano),
  stato_giocatore(Stato),
  % Lunghezza della mano tra 0 e 2
  (
    Stato = fuori -> Mano = []; % Se lo stato è "fuori", la mano dovrà essere vuota.

    length(Mano, L), % Se il giocatore è in gioco, avrà una o due carte in mano.
    between(1, 2, L)
  ).

/*
stato_round(
  Giocatori, % lista
  Mazzo, % lista
  Scarti, % lista
  CartaRimossa, % carta rimossa dal gioco a inizio round
  TurnoDi % indice del giocatore di cui è il turno
).
*/

% Helper per rimuovere la prima apparizione di un elemento in una lista.
% Controlla anche la sua presenza.
rimuovi_primo(_, [], []) :- !, fail.
rimuovi_primo(X, [X|T], T) :- !.
rimuovi_primo(X, [H|T], [H|R]) :-
    rimuovi_primo(X, T, R).

% Modifica un giocatore in una lista di giocatori.
aggiorna_giocatore(Giocatore, NuovoGiocatore, [giocatore(Giocatore, _, _) | R], [NuovoGiocatore | R]).
aggiorna_giocatore(Giocatore, NuovoGiocatore, [P | R], [P | NR]) :-
    aggiorna_giocatore(Giocatore, NuovoGiocatore, R, NR).

% Rimuovi una carta dalla mano di un giocatore e inseriscila negli scarti
rimuovi_carta(Carta, Giocatore,
  stato_round(Giocatori, Mazzo, Scarti, CartaRimossa, TurnoDi),
  stato_round(NuovoGiocatori, Mazzo, NuovoScarti, CartaRimossa, TurnoDi)) :-
  member(giocatore(Giocatore, Mano, StatoGiocatore), Giocatori),
  rimuovi_primo(Carta, Mano, NuovoMano),
  aggiorna_giocatore(Giocatore, giocatore(Giocatore, NuovoMano, StatoGiocatore), Giocatori, NuovoGiocatori),
  append(Scarti, [Carta], NuovoScarti).

% Pesca una carta dal mazzo e aggiungila alla mano del giocatore
pesca_carta(Giocatore,
  stato_round(Giocatori, [CartaPescata | NuovoMazzo], Scarti, CartaRimossa, TurnoDi),
  stato_round(NuovoGiocatori, NuovoMazzo, Scarti, CartaRimossa, TurnoDi)) :-
  member(giocatore(Giocatore, Mano, StatoGiocatore), Giocatori),
  append(Mano, [CartaPescata], NuovoMano),
  aggiorna_giocatore(Giocatore, giocatore(Giocatore, NuovoMano, StatoGiocatore), Giocatori, NuovoGiocatori).

% gioca_carta(Carta, Giocatore, Bersaglio, StatoRoundIn, StatoRoundOut).
% Senza punteggi, la carta spia è una carta senza effetto
gioca_carta(spia, Giocatore, _, Stato, NuovoStato) :-
    rimuovi_carta(spia, Giocatore, Stato, NuovoStato).

:- initialization(main).
main :-
  G1 = giocatore(pippo, [guardia, spia], dentro),
  G2 = giocatore(pluto, [barone], dentro),
  G3 = giocatore(paperino, [], fuori),

  giocatore_valido(G1),
  giocatore_valido(G2),
  giocatore_valido(G3),

  SR = stato_round([G1, G2, G3], [re, principessa, barone, contessa], [prete, guardia, spia, guardia], principe, pippo),

  gioca_carta(spia, pippo, _, SR, NSR),
  pesca_carta(pluto, NSR, NNSR),
  write(NNSR), nl, nl.
