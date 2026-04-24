:- module(informazione, [informazione/1, lista_informazioni/1, riguarda_giocatore_e_carta/3, riguarda_carta/2, riguarda_giocatore/2, riguarda_visione/2, scambia_informazioni/4]).

:- use_module('../mazzo').

% Informazioni sulla mano:
%
% carta_posseduta(Giocatore, Carta) - mutuamente esclusiva alle altre info
% carta_non_posseduta(Giocatore, Carta)
% carta_superiore(Giocatore, Valore)
% carta_uguale(Giocatore, Giocatore)
% carta_in_posizione(Carta, Posizione) - posizione dal fondo del mazzo
% protetto(Giocatore) - giocatore protetto per un turno dall'effetto di domestica
informazione(carta_posseduta(_, _)).
informazione(carta_non_posseduta(_, _)).
informazione(carta_superiore(_, _)).
informazione(carta_uguale(_, _)).
informazione(carta_in_posizione(_, _)).
informazione(protetto(_)).

% Si tratta di una lista di informazioni
lista_informazioni(L) :-
    forall(member(M, L), informazione(M)).

riguarda_carta(C, carta_posseduta(_, C)).
% "riguarda_carta" indica se un informazione è compatibile con una determinata carta.
% Pertanto, il non-possedimento (controintuitivamente) riguarda "tutte le carte che non sono la non-posseduta".
riguarda_carta(C1, carta_non_posseduta(_, C2)) :-
    C1 \= C2.
riguarda_carta(C, carta_superiore(_, V)) :-
    valore(C, Vc),
    Vc >= V.
riguarda_carta(C, carta_in_posizione(C, _)).
riguarda_carta(_, carta_uguale(_, _)).

riguarda_giocatore(G, carta_posseduta(G, _)).
riguarda_giocatore(G, carta_non_posseduta(G, _)).
riguarda_giocatore(G, carta_superiore(G, _)).
riguarda_giocatore(G, carta_uguale(G, _)).
riguarda_giocatore(G, carta_uguale(_, G)).
riguarda_giocatore(G, protetto(G)).

riguarda_giocatore_senza_uguale(G, I) :-
    I \= carta_uguale(_, _),
    riguarda_giocatore(G, I).

riguarda_giocatore_e_carta(Giocatore, Carta, I) :-
    riguarda_carta(Carta, I),
    riguarda_giocatore(Giocatore, I).

% Caso particolare per la visione della carta di un giocatore.
% Voglio permettere l'evento carta_vista anche durante l'effetto di domestica,
% così da poter rappresetnare anche il peeking delle carte altrui.
riguarda_visione(Giocatore, I) :-
  I \= protetto(Giocatore),
  riguarda_giocatore(Giocatore, I).

scambia_giocatore(G1, G2, I, I2) :-
    \+ riguarda_giocatore(G1, I),
    riguarda_giocatore(G2, I),
    scambia_giocatore(G2, G1, I, I2).
scambia_giocatore(G1, G2, carta_posseduta(G1, C), carta_posseduta(G2, C)).
scambia_giocatore(G1, G2, carta_non_posseduta(G1, C), carta_non_posseduta(G2, C)).
scambia_giocatore(G1, G2, carta_superiore(G1, V), carta_superiore(G2, V)).
% caso in cui si scambia tra due giocatori legati
scambia_giocatore(G1, G2, carta_uguale(G1, G2), carta_uguale(G1, G2)).
scambia_giocatore(G1, G2, carta_uguale(G1, Gd), carta_uguale(G2, Gd)) :-
    G2 \= Gd.
scambia_giocatore(G1, G2, carta_uguale(Gd, G1), carta_uguale(Gd, G2)) :-
    G2 \= Gd.
% info non legata a nessuno dei due giocatori: passa invariata
scambia_giocatore(G1, G2, I, I) :-
    \+ riguarda_giocatore(G1, I),
    \+ riguarda_giocatore(G2, I).

scambia_informazioni(G1, G2, InformazioniDaCambiare, NuoveInformazioni) :-
    G1 \== G2,
    findall(I2,
            (
                member(I1, InformazioniDaCambiare),
                scambia_giocatore(G1, G2, I1, I2)
            ),
            NuoveInformazioni
    ).
