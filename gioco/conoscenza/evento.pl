:- module(evento, [evento/1, giocatore/2, usa_carta/2, bersaglio/2, eliminato/3, incerto/1]).

:- reexport(['evento/registrazione', 'evento/possibile']).

% Eventi transitori
evento(carta_scartata(_, _)).
evento(carta_tolta(_, _)).
evento(carta_vista(_, _)).
evento(giocatore_eliminato(_, _)).
evento(giocatore_autoeliminato(_, _)).

% Eventi di gioco
evento(carta_giocata(_, spia)).
evento(carta_giocata(_, guardia, _, _, true)).
evento(carta_giocata(_, guardia, _, _, false)).
% Senza conoscerne la carta
evento(carta_giocata(_, prete, _)).
% Conoscendone la carta
evento(carta_giocata(_, prete, _, _)).
evento(carta_giocata(_, barone, _)).
evento(carta_giocata(_, barone, _, _, _)).
evento(carta_giocata(_, domestica)).
evento(carta_giocata(_, principe, _, _)).
evento(carta_giocata(_, cancelliere, _, _, _)).
evento(carta_giocata(_, cancelliere)).
% Senza conoscere le mani scambiate
evento(carta_giocata(_, re, _)).
% Conoscendo le mani scambiate
evento(carta_giocata(_, re, _, _, _)).
evento(carta_giocata(_, contessa)).
evento(carta_giocata(_, principessa, _)).
% Fallback per quando una qualunque carta non può essere attivata
evento(carta_giocata(_, _)).

% Giocatore del turno
giocatore(Giocatore, carta_giocata(Giocatore, spia)).
giocatore(Giocatore, carta_giocata(Giocatore, guardia, _, _, _)).
giocatore(Giocatore, carta_giocata(Giocatore, prete, _)).
giocatore(Giocatore, carta_giocata(Giocatore, prete, _, _)).
giocatore(Giocatore, carta_giocata(Giocatore, barone, _)).
giocatore(Giocatore, carta_giocata(Giocatore, barone, _, _, _)).
giocatore(Giocatore, carta_giocata(Giocatore, domestica)).
giocatore(Giocatore, carta_giocata(Giocatore, principe, _, _)).
giocatore(Giocatore, carta_giocata(Giocatore, cancelliere, _, _, _)).
giocatore(Giocatore, carta_giocata(Giocatore, cancelliere)).
giocatore(Giocatore, carta_giocata(Giocatore, re, _)).
giocatore(Giocatore, carta_giocata(Giocatore, re, _, _, _)).
giocatore(Giocatore, carta_giocata(Giocatore, contessa)).
giocatore(Giocatore, carta_giocata(Giocatore, principessa, _)).
giocatore(Giocatore, carta_giocata(Giocatore, _)).

% Carta utilizzata nella giocata
usa_carta(spia, carta_giocata(_, spia)).
usa_carta(guardia, carta_giocata(_, guardia, _, _, _)).
usa_carta(prete, carta_giocata(_, prete, _)).
usa_carta(prete, carta_giocata(_, prete, _, _)).
usa_carta(barone, carta_giocata(_, barone, _)).
usa_carta(barone, carta_giocata(_, barone, _, _, _)).
usa_carta(domestica, carta_giocata(_, domestica)).
usa_carta(principe, carta_giocata(_, principe, _, _)).
usa_carta(cancelliere, carta_giocata(_, cancelliere, _, _, _)).
usa_carta(cancelliere, carta_giocata(_, cancelliere)).
usa_carta(re, carta_giocata(_, re, _)).
usa_carta(re, carta_giocata(_, re, _, _, _)).
usa_carta(contessa, carta_giocata(_, contessa)).
usa_carta(principessa, carta_giocata(_, principessa, _)).
usa_carta(Carta, carta_giocata(_, Carta)).

% Eventi con bersaglio
bersaglio(Bersaglio, carta_giocata(_, guardia, Bersaglio, _, _)).
bersaglio(Bersaglio, carta_giocata(_, prete, Bersaglio)).
bersaglio(Bersaglio, carta_giocata(_, prete, Bersaglio, _)).
bersaglio(Bersaglio, carta_giocata(_, barone, Bersaglio)).
bersaglio(Bersaglio, carta_giocata(_, barone, Bersaglio, _, _)).
bersaglio(Bersaglio, carta_giocata(_, principe, Bersaglio, _)).
bersaglio(Bersaglio, carta_giocata(_, re, Bersaglio, _, _)).

% Eventi con eliminazione di un giocatore.
% Ogni eliminazione implica anche che una carta esca dal gioco.
eliminato(Eliminato, CartaEliminata, carta_giocata(_, guardia, Eliminato, CartaEliminata, true)).   % solo con true si elimina un giocatore
eliminato(Eliminato, CartaEliminata, carta_giocata(_, barone, _, Eliminato, CartaEliminata)).
eliminato(Eliminato, principessa, carta_giocata(_, principe, Eliminato, principessa)).   % implica eliminazione solo se si scarta la principessa
eliminato(Eliminato, CartaEliminata, carta_giocata(Eliminato, principessa, CartaEliminata)).

% Eventi senza conoscenza totale, dal punto di vista dell'agente conoscitivo
incerto(carta_giocata(_, prete, _)).
incerto(carta_giocata(_, cancelliere)).
incerto(carta_giocata(_, re, _)).
