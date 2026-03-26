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

conta(_, [], 0).
conta(X, [X|T], N) :- !, conta(X, T, N1), N is N1 + 1.
conta(X, [_|T], N) :- conta(X, T, N).

% =============================================================================
% CONOSCENZA PARZIALE
% Vista soggettiva di un osservatore (il giocatore che sta ragionando).
%
% conoscenza(
%   Osservatore,      % nome del giocatore che ragiona
%   ManoPropria,      % lista di carte (nota con certezza)
%   CarteAvversari,   % lista di giocatore-carta NOTI (da effetti carte come prete)
%   CartaRimossaNota, % 'sconosciuta' oppure una carta specifica
%   Scarti            % sempre visibili a tutti
% )
% =============================================================================

conoscenza_valida(conoscenza(Osservatore, ManoPropria, CarteAvversari, CartaRimossa, Scarti)) :-
    atom(Osservatore),
    lista_di_carte(ManoPropria),
    is_list(CarteAvversari),  % lista di Nome-Carta per le carte note degli avversari
    (CartaRimossa = sconosciuta -> true ; carta(CartaRimossa)),
    lista_di_carte(Scarti).

% =============================================================================
% MULTISET: il mazzo è rappresentato come lista di coppie carta-conteggio
% es: [guardia-3, prete-2, barone-1, ...]
% =============================================================================

% Aggiorna il conteggio di una carta nel multiset
aggiorna_copie(Carta, N, [Carta-_ | R], [Carta-N | R]) :- !.
aggiorna_copie(Carta, N, [H | R],       [H | NR]) :-
    aggiorna_copie(Carta, N, R, NR).

% Rimuovi una carta dal multiset (decrementa il conteggio, elimina se 0)
rimuovi_da_multiset(Carta, Multiset, NuovoMultiset) :-
    member(Carta-N, Multiset),
    N > 0,
    N1 is N - 1,
    (
        N1 =:= 0
    ->  rimuovi_primo(Carta-N, Multiset, NuovoMultiset)
    ;   aggiorna_copie(Carta, N1, Multiset, NuovoMultiset)
    ).

% Pesca una carta dal multiset (non-deterministico: quale carta è stata pescata?)
% Backtracking su questo predicato enumera tutte le carte possibili.
pesca_da_multiset(Carta, Multiset, NuovoMultiset) :-
    member(Carta-N, Multiset),
    N > 0,
    rimuovi_da_multiset(Carta, Multiset, NuovoMultiset).

% Costruisce il multiset iniziale delle carte ancora "libere",
% sottraendo le carte note: mani dei giocatori + scarti + carta rimossa.
inizializza_multiset(
        conoscenza(_, ManoPropria, CarteAvversari, CartaRimossa, Scarti),
        Multiset) :-
    % Carte degli avversari note (solo quelle vincolate)
    findall(C, member(_-C, CarteAvversari), CarteAvversariNote),
    % Tutte le carte che sappiamo con certezza dove si trovano
    append(ManoPropria, CarteAvversariNote, Tmp1),
    append(Tmp1, Scarti, Tmp2),
    % La carta rimossa: la sottraiamo solo se la conosciamo
    (CartaRimossa = sconosciuta
    ->  CarteNote = Tmp2
    ;   append(Tmp2, [CartaRimossa], CarteNote)
    ),
    findall(Carta-CopieLibere,
        (
            carta(Carta),
            numero_copie(Carta, TotCopie),
            conta(Carta, CarteNote, Usate),
            CopieLibere is TotCopie - Usate,
            CopieLibere > 0
        ),
        Multiset).
