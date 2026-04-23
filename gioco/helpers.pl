:- module(helpers, [conta/3]).

% Conta le occorrenze di un elemento in una lista
conta(_, [], 0).
conta(X, [X|T], N) :- !, conta(X, T, N1), N is N1 + 1.
conta(X, [_|T], N) :- conta(X, T, N).
