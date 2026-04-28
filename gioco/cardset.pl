:- module(cardset, [cardset/1, cardset_pieno/1, cardset_vuoto/1, cardset_complemento/2, rimuovi_da_cardset/4, aggiungi_a_cardset/4, controllo_posizione/3, pesca_informata_cardset/5, carta_presente/2, copie_carta/3, carte_in_cardset/2]).

:- use_module(mazzo),
use_module('conoscenza/informazione').

% cs(Spia, Guardia, Prete, Barone, Domestica, Principe, Cancelliere, Re, Contessa, Principessa)

cardset(cs(_, _, _, _, _, _, _, _, _, _)).
cardset_vuoto(cs(0, 0, 0, 0, 0, 0, 0, 0, 0, 0)).
cardset_pieno(cs(S, G, P, B, D, Pr, Ca, R, Co, Pp)) :-
    numero_copie(spia, S), numero_copie(guardia, G), numero_copie(prete, P),
    numero_copie(barone, B), numero_copie(domestica, D), numero_copie(principe, Pr),
    numero_copie(cancelliere, Ca), numero_copie(re, R), numero_copie(contessa, Co),
    numero_copie(principessa, Pp).

rimuovi_da_cardset(spia, cs(N1, G, P, B, D, Pr, Ca, R, Co, Pp), cs(N2, G, P, B, D, Pr, Ca, R, Co, Pp), N1) :- N1>0, N2 is N1-1.
rimuovi_da_cardset(guardia, cs(S, N1, P, B, D, Pr, Ca, R, Co, Pp), cs(S, N2, P, B, D, Pr, Ca, R, Co, Pp), N1) :- N1>0, N2 is N1-1.
rimuovi_da_cardset(prete, cs(S, G, N1, B, D, Pr, Ca, R, Co, Pp), cs(S, G, N2, B, D, Pr, Ca, R, Co, Pp), N1) :- N1>0, N2 is N1-1.
rimuovi_da_cardset(barone, cs(S, G, P, N1, D, Pr, Ca, R, Co, Pp), cs(S, G, P, N2, D, Pr, Ca, R, Co, Pp), N1) :- N1>0, N2 is N1-1.
rimuovi_da_cardset(domestica, cs(S, G, P, B, N1, Pr, Ca, R, Co, Pp), cs(S, G, P, B, N2, Pr, Ca, R, Co, Pp), N1) :- N1>0, N2 is N1-1.
rimuovi_da_cardset(principe, cs(S, G, P, B, D, N1, Ca, R, Co, Pp), cs(S, G, P, B, D, N2, Ca, R, Co, Pp), N1) :- N1>0, N2 is N1-1.
rimuovi_da_cardset(cancelliere, cs(S, G, P, B, D, Pr, N1, R, Co, Pp), cs(S, G, P, B, D, Pr, N2, R, Co, Pp), N1) :- N1>0, N2 is N1-1.
rimuovi_da_cardset(re, cs(S, G, P, B, D, Pr, Ca, N1, Co, Pp), cs(S, G, P, B, D, Pr, Ca, N2, Co, Pp), N1) :- N1>0, N2 is N1-1.
rimuovi_da_cardset(contessa, cs(S, G, P, B, D, Pr, Ca, R, N1, Pp), cs(S, G, P, B, D, Pr, Ca, R, N2, Pp), N1) :- N1>0, N2 is N1-1.
rimuovi_da_cardset(principessa, cs(S, G, P, B, D, Pr, Ca, R, Co, N1), cs(S, G, P, B, D, Pr, Ca, R, Co, N2), N1) :- N1>0, N2 is N1-1.

% Aggiunge una carta al cardset.
% Restituisce il numero di copie presenti dopo l'aggiunta.
aggiungi_a_cardset(spia, cs(N1, G, P, B, D, Pr, Ca, R, Co, Pp), cs(N2, G, P, B, D, Pr, Ca, R, Co, Pp), N2) :- numero_copie(spia, Max), N2 is N1+1, N2=<Max.
aggiungi_a_cardset(guardia, cs(S, N1, P, B, D, Pr, Ca, R, Co, Pp), cs(S, N2, P, B, D, Pr, Ca, R, Co, Pp), N2) :- numero_copie(guardia, Max), N2 is N1+1, N2=<Max.
aggiungi_a_cardset(prete, cs(S, G, N1, B, D, Pr, Ca, R, Co, Pp), cs(S, G, N2, B, D, Pr, Ca, R, Co, Pp), N2) :- numero_copie(prete, Max), N2 is N1+1, N2=<Max.
aggiungi_a_cardset(barone, cs(S, G, P, N1, D, Pr, Ca, R, Co, Pp), cs(S, G, P, N2, D, Pr, Ca, R, Co, Pp), N2) :- numero_copie(barone, Max), N2 is N1+1, N2=<Max.
aggiungi_a_cardset(domestica, cs(S, G, P, B, N1, Pr, Ca, R, Co, Pp), cs(S, G, P, B, N2, Pr, Ca, R, Co, Pp), N2) :- numero_copie(domestica, Max), N2 is N1+1, N2=<Max.
aggiungi_a_cardset(principe, cs(S, G, P, B, D, N1, Ca, R, Co, Pp), cs(S, G, P, B, D, N2, Ca, R, Co, Pp), N2)  :- numero_copie(principe, Max), N2 is N1+1, N2=<Max.
aggiungi_a_cardset(cancelliere, cs(S, G, P, B, D, Pr, N1, R, Co, Pp), cs(S, G, P, B, D, Pr, N2, R, Co, Pp), N2)  :- numero_copie(cancelliere, Max), N2 is N1+1, N2=<Max.
aggiungi_a_cardset(re, cs(S, G, P, B, D, Pr, Ca, N1, Co, Pp), cs(S, G, P, B, D, Pr, Ca, N2, Co, Pp), N2) :- numero_copie(re, Max), N2 is N1+1, N2=<Max.
aggiungi_a_cardset(contessa, cs(S, G, P, B, D, Pr, Ca, R, N1, Pp), cs(S, G, P, B, D, Pr, Ca, R, N2, Pp), N2)  :- numero_copie(contessa, Max), N2 is N1+1, N2=<Max.
aggiungi_a_cardset(principessa, cs(S, G, P, B, D, Pr, Ca, R, Co, N1), cs(S, G, P, B, D, Pr, Ca, R, Co, N2), N2)  :- numero_copie(principessa, Max), N2 is N1+1, N2=<Max.

copie_carta(spia, cs(N, _, _, _, _, _, _, _, _, _), N).
copie_carta(guardia, cs(_, N, _, _, _, _, _, _, _, _), N).
copie_carta(prete, cs(_, _, N, _, _, _, _, _, _, _), N).
copie_carta(barone, cs(_, _, _, N, _, _, _, _, _, _), N).
copie_carta(domestica, cs(_, _, _, _, N, _, _, _, _, _), N).
copie_carta(principe, cs(_, _, _, _, _, N, _, _, _, _), N).
copie_carta(cancelliere, cs(_, _, _, _, _, _, N, _, _, _), N).
copie_carta(re, cs(_, _, _, _, _, _, _, N, _, _), N).
copie_carta(contessa, cs(_, _, _, _, _, _, _, _, N, _), N).
copie_carta(principessa, cs(_, _, _, _, _, _, _, _, _, N), N).

carte_in_cardset(cs(S, G, P, B, D, Pr, Ca, R, Co, Pp), N) :-
    N is S+G+P+B+D+Pr+Ca+R+Co+Pp.

cardset_complemento(cs(S1, G1, P1, B1, D1, Pr1, Ca1, R1, Co1, Pp1), cs(S2, G2, P2, B2, D2, Pr2, Ca2, R2, Co2, Pp2)) :-
    numero_copie(spia, SM),
    numero_copie(guardia, GM),
    numero_copie(prete, PM),
    numero_copie(barone, BM),
    numero_copie(domestica, DM),
    numero_copie(principe, PrM),
    numero_copie(cancelliere, CaM),
    numero_copie(re, RM),
    numero_copie(contessa, CoM),
    numero_copie(principessa, PpM),
    between(0, SM, S1),
    between(0, GM, G1),
    between(0, PM, P1),
    between(0, BM, B1),
    between(0, DM, D1),
    between(0, PrM, Pr1),
    between(0, CaM, Ca1),
    between(0, RM, R1),
    between(0, CoM, Co1),
    between(0, PpM, Pp1),
    S2 is SM - S1,
    G2 is GM - G1,
    P2 is PM - P1,
    B2 is BM - B1,
    D2 is DM - D1,
    Pr2 is PrM - Pr1,
    Ca2 is CaM - Ca1,
    R2 is RM - R1,
    Co2 is CoM - Co1,
    Pp2 is PpM - Pp1.

% Controllo del posizionamento delle carte.
% Non richiede giocatore o stati precedenti, utile durante azioni di pesca generiche.
controllo_posizione(Carta, Info, Cardset) :-
    % Controllo di pesca alla posizione esatta
    carte_in_cardset(Cardset, PosizioneNelMazzo),
    \+ (
           member(carta_in_posizione(CartaPos, PosizioneNelMazzo), Info),
           dif(Carta, CartaPos)
       ),
    % Controllo che non si usino copie extra ad una posizione quando si sa che devono essere in un altra.
    \+ (
           conta_vincoli_pos_precedenti(Carta, PosizioneNelMazzo, Info, N),
           N > 0,
           copie_carta(Carta, Cardset, Copie),
           Copie =< N
       ).

vincolo_precedente(Carta, PosMax, carta_in_posizione(Carta, P)) :-
    P < PosMax.

conta_vincoli_pos_precedenti(Carta, PosMax, Info, N) :-
    include(vincolo_precedente(Carta, PosMax), Info, Matching),
    length(Matching, N).

pesca_informata_cardset(C, I, M1, M2, Peso) :-
    controllo_posizione(C, I, M1),
    rimuovi_da_cardset(C, M1, M2, Peso).

% Vero se è presente almeno una copia della carta nel cardset.
carta_presente(Carta, Cardset) :-
    copie_carta(Carta, Cardset, N),
    N > 0.
