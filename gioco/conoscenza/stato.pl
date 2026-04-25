:- module(stato, [stato_possibile/3, mani/2, mano/3, mazzo/2, carta_rimossa/2]).

:- use_module('../mazzo'),
use_module(informazione),
use_module('../cardset').

% Cardset delle carte in gioco
inizializza_mazzo(Conoscenza, Cardset) :-
    scarti(Conoscenza, Scarti),
    cardset_complemento(Scarti, Cardset).

% Stato di gioco possibile data una conoscenza. Non deterministico.
%
% Struttura di uno stato:
% stato([Giocatore-CartaInMano, ...], [CartaNelMazzo-NumeroDiCopie, ...], CartaRimossa)
stato_possibile(C, stato(ManoGiocatori, M2, CartaRimossa), Peso) :-
    C = conoscenza(Giocatori, Informazioni, _),
    inizializza_mazzo(C, M0),
    rimuovi_da_cardset(CartaRimossa, M0, M1, P1),
    mano_giocatori(Giocatori, Informazioni, M1, ManoGiocatori, [], M2, P2),
    Peso is P1 * P2.

mani(ManoGiocatori, stato(ManoGiocatori, _, _)).
mano(Giocatore, Mano, S) :-
    mani(ManoGiocatori, S),
    member(Giocatore-Mano, ManoGiocatori).
mazzo(Mazzo, stato(_, Mazzo, _)).
carta_rimossa(CartaRimossa, stato(_, _, CartaRimossa)).

vincoli(G, C, Informazioni, CarteInMano, Cardset) :-
    % Anzichè usare ->, per favorire backtracking si usa una logica inversa.
    % "Non voglio che (ci sia una regola E non sia rispettata)"
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
    controllo_posizione(C, Informazioni, Cardset).

% Assegna ad ogni giocatore una carta, come nello stato solito di una partita.
mano_giocatori([], _, M, [], _, M, 1).
% con carta nota
mano_giocatori([G|Gs], Informazioni, M1, [G-C|R], Acc, MFinale, Peso) :-
    member(carta_posseduta(G, C), Informazioni),
    exclude(=(carta_posseduta(G, C)), Informazioni, InformazioniRestanti),
    rimuovi_da_cardset(C, M1, M2, P1),
    mano_giocatori(Gs, InformazioniRestanti, M2, R, [G-C|Acc], MFinale, P2),
    Peso is P1 * P2.
% senza una carta nota
mano_giocatori([G|Gs], Informazioni, M1, [G-C|R], Acc, MFinale, Peso) :-
    \+ member(carta_posseduta(G, _), Informazioni),
    vincoli(G, C, Informazioni, Acc, M1), % cardset considerato *prima* di pescare
    rimuovi_da_cardset(C, M1, M2, P1),
    mano_giocatori(Gs, Informazioni, M2, R, [G-C|Acc], MFinale, P2),
    Peso is P1 * P2.
