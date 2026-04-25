:- module(valido, [turno_possibile/2]).

:- use_module('../evento'),
use_module('../stato'),
use_module('../../conoscenza'),
use_module('../../mazzo'),
use_module('../../cardset').

turno_possibile(Conoscenza, Evento) :-
    giocatore_corrente(Conoscenza, Giocatore),
    controllo_protezione(Conoscenza, Evento),
    % TODO: è più efficiente valutare prima lo stato o le giocate?
    stato_possibile(Conoscenza, Stato),
    giocata_possibile_stato(Giocatore, Stato, Evento).

controllo_protezione(Conoscenza, Evento) :-
    informazioni(Conoscenza, Informazioni),
    % Se i giocatori avversari sono protetti, allora non si possono bersagliare.
    forall(member(protetto(G), Informazioni), \+ bersaglio(G, Evento)).

giocata_possibile_stato(Giocatore, Stato, Evento) :-
    giocatore(Giocatore, Evento),
    mano(Giocatore, CartaInMano, Stato),
    mazzo(Mazzo, Stato),
    % si gioca la carta già in mano o quella pescata
    (
        CartaGiocata = CartaInMano,
        carte_in_cardset(Mazzo, PesoCartaGiocata) % utilizzabile in ogni caso di pesca
    ;
        rimuovi_da_cardset(CartaGiocata, Mazzo, _, PesoCartaGiocata) % utilizzabile solo in N casi di pesca
    ),
    usa_carta(CartaGiocata, Evento).
% TODO: branching nei casi specifici delle diverse carte (bersaglio, eliminazione, etc)
% TODO: come gestire il caso in cui il giocante o il bersaglio è conoscitivo?
