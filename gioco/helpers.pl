:- module(helpers, [conta/3, rimuovi_primo/3]).

% Conta le occorrenze di un elemento in una lista
conta(_, [], 0).
conta(X, [X|T], N) :- !, conta(X, T, N1), N is N1 + 1.
conta(X, [_|T], N) :- conta(X, T, N).

% Rimuove la prima apparizione di un elemento in una lista.
rimuovi_primo(_, [], []).
rimuovi_primo(X, [X|T], T) :- !.
rimuovi_primo(X, [H|T], [H|R]) :-
    rimuovi_primo(X, T, R).
