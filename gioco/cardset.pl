:- module(cardset, [inizializza_multiset/2, aggiorna_copie/4, rimuovi_da_multiset/3, pesca_da_multiset/4, carte_in_multiset/2]).

:- use_module(mazzo),
    use_module('conoscenza/conoscenza'),
    use_module(helpers).

% Multiset lista di coppie carta-conteggio, es: [guardia-3, prete-2, ...]

% Multiset delle carte in gioco
inizializza_multiset(Conoscenza, Multiset) :-
    scarti(Conoscenza, CarteNote),
    findall(Carta-CopieLibere,
            (
                carta(Carta),
                numero_copie(Carta, TotCopie),
                conta(Carta, CarteNote, Usate),
                CopieLibere is TotCopie - Usate,
                CopieLibere >= 0
            ),
            Multiset).

% Aggiorna il conteggio di una carta nel multiset
aggiorna_copie(Carta, N, [Carta-_  |R], [Carta-N  |R]) :- !.
aggiorna_copie(Carta, N, [H  |R], [H  |NR]) :-
    aggiorna_copie(Carta, N, R, NR).

% Rimuovi una carta dal multiset (decrementa il conteggio)
rimuovi_da_multiset(Carta, Multiset, NuovoMultiset) :-
    member(Carta-N, Multiset),
    N > 0,
    N1 is N - 1,
    aggiorna_copie(Carta, N1, Multiset, NuovoMultiset).

% Pesca una carta dal multiset (non-deterministico).
% Enumera il numero di copie presenti al momento della pesca.
pesca_da_multiset(Carta, Multiset, NuovoMultiset, N) :-
    member(Carta-N, Multiset),
    N > 0,
    rimuovi_da_multiset(Carta, Multiset, NuovoMultiset).

carte_in_multiset(Multiset, N) :-
    aggregate_all(
        sum(Copie),
        member(_-Copie, Multiset),
        N
    ).
