% Se si tratta di una lista di carte
lista_di_carte([]).
lista_di_carte([H | R]) :-
  (nonvar(H) -> carta(H) ; true),
  lista_di_carte(R).

% Se si tratta di un giocatore.
lista_di_giocatori([]).
lista_di_giocatori([H | R]) :-
  (nonvar(H) -> giocatore_valido(H) ; true),
  lista_di_giocatori(R).

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

stato_round_valido(stato_round(Giocatori, Mazzo, Scarti, CartaRimossa, TurnoDi)) :-
  stato_round_valido(Giocatori, Mazzo, Scarti, CartaRimossa, TurnoDi).
stato_round_valido(
  Giocatori, % lista
  Mazzo, % lista
  Scarti, % lista
  CartaRimossa, % carta rimossa dal gioco a inizio round
  TurnoDi % indice del giocatore di cui è il turno
) :-
  lista_di_giocatori(Giocatori),
  is_list(Mazzo), % un multiset sempre istanziato
  lista_di_carte(Scarti),
  carta(CartaRimossa),
  member(giocatore(TurnoDi, _, dentro), Giocatori). % il turno è di un giocatore in gioco.

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
  stato_round(Giocatori, Mazzo, Scarti, CartaRimossa, TurnoDi),
  stato_round(NuovoGiocatori, NuovoMazzo, Scarti, CartaRimossa, TurnoDi)) :-
  member(giocatore(Giocatore, Mano, StatoGiocatore), Giocatori),
  pesca_da_multiset(CartaPescata, Mazzo, NuovoMazzo),
  append(Mano, [CartaPescata], NuovoMano),
  aggiorna_giocatore(Giocatore, giocatore(Giocatore, NuovoMano, StatoGiocatore), Giocatori, NuovoGiocatori).

% gioca_carta(Carta, Giocatore, Bersaglio, StatoRoundIn, StatoRoundOut).
% Senza punteggi, la carta spia è una carta senza effetto
gioca_carta(spia, Giocatore, _, Stato, NuovoStato) :-
    rimuovi_carta(spia, Giocatore, Stato, NuovoStato).

:- initialization(main).
main :-
  consult(mazzo),
  consult(statistica),

  GiocatoreOsservatore = pippo,
  ManoOsservatore = [guardia, spia],
  G1 = giocatore(GiocatoreOsservatore, ManoOsservatore, dentro),
  G3 = giocatore(paperino, [], fuori),

  Scarti = [prete, guardia, spia, guardia],

  Conoscenza = conoscenza(
          GiocatoreOsservatore,
          ManoOsservatore,        % la tua mano
          [pluto-barone],
          sconosciuta,            % non sai cosa è stato rimosso
          Scarti % scarti visibili
      ),

  inizializza_multiset(Conoscenza, MultisetPrePluto),

  giocatore_valido(G1),
  giocatore_valido(G3),

  findall(ManoPluto-MultisetFinale,
      (
          % Entrambe le pescate dentro findall, così backtracking le esplora entrambe
          pesca_da_multiset(CartaPluto, MultisetPrePluto, Multiset),
          G2 = giocatore(pluto, [barone], dentro),
          giocatore_valido(G2),

          S1 = stato_round([G1, G2, G3], Multiset, Scarti, principessa, pippo),
          stato_round_valido(S1),
          gioca_carta(spia, pippo, _, S1, S2),
          pesca_carta(pluto, S2, S3),
          S3 = stato_round(G3s, MultisetFinale, _, _, _),
          member(giocatore(pluto, ManoPluto, _), G3s)
      ),
      Possibilita
  ),
  write('Possibili mani di pluto:'), nl,
      forall(member(Mano-Rim, Possibilita),
          (write('  '), write(Mano), write(' | rimanente: '), write(Rim), nl)),

  nl, write('Probabilità che pluto abbia ciascuna carta:'), nl,
  stampa_probabilita(Possibilita).
