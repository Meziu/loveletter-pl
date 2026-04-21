:- module(helpers, [conta/3, is_lista_carte/1, rimuovi_primo/3, bool/1]).

:- use_module(mazzo).

% Conta le occorrenze di un elemento in una lista
conta(_, [], 0).
conta(X, [X|T], N) :- !, conta(X, T, N1), N is N1 + 1.
conta(X, [_|T], N) :- conta(X, T, N).

% Si tratta di una lista di carte
is_lista_carte(L) :-
    forall(member(M, L), carta(M)).

% Rimuove la prima apparizione di un elemento in una lista.
rimuovi_primo(_, [], []).
rimuovi_primo(X, [X|T], T) :- !.
rimuovi_primo(X, [H|T], [H|R]) :-
    rimuovi_primo(X, T, R).

% TODO: trovare una soluzione migliore
bool(true).
bool(false).
