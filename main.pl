:- consult(mazzo),
consult(statistica),
consult(conoscenza),
initialization(main).

%write('=== ANALISI: probabilità mano di pippo dopo il gioco di 2 cancellieri ==='), nl,
%C1 = conoscenza([pippo, pluto], [carta_uguale(pippo, pluto), carta_non_posseduta(pippo, principessa)], sconosciuta, []),
%reg_eventi(C1, [carta_giocata(pluto, cancelliere, re, barone, prete), carta_giocata(pippo, cancelliere)], C2),
%stampa_probabilita_mano(C2, pippo).

%C1 = conoscenza([pippo, pluto], [carta_uguale(pippo, pluto), carta_non_posseduta(pippo, contessa)], sconosciuta, []),
%reg_eventi(C1, [carta_giocata(pluto, cancelliere, re, barone, prete), carta_giocata(pippo, contessa)], C2),
%stampa_probabilita_mano(C2, pippo).

main :-
    run_test(test_carta_scartata),
    run_test(test_carta_vista),
    run_test(test_eliminato),
    run_test(test_autoeliminato),
    run_test(test_guardia_no_elim),
    run_test(test_guardia_elim),
    run_test(test_barone_uguaglianza),
    run_test(test_principe),
    run_test(test_re_scambio),
    run_test(test_contessa),
    run_test(test_principessa),
    run_test(test_principe_prete),
    run_test(test_barone_guardia),
    run_test(test_re_scambio_cascade),
    run_test(test_principessa_autoeliminazione),
    run_test(test_cancellieri_catenati),
    writeln('Fine test.').

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FRAMEWORK SICURO (mai fallisce)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run_test(Test) :-
    (   catch(call(Test), E,
            ( format('❌ Eccezione in ~w: ~w~n', [Test, E]), fail ))
    ->  true
    ;   format('❌ Test fallito (crash): ~w~n', [Test])
    ).

check(Nome, Goal) :-
    (   call(Goal)
    ->  true
    ;   format('❌ Check fallito: ~w~n', [Nome])
    ).

test_carta_scartata :-
    (   C0 = conoscenza([a,b],
            [carta_posseduta(a, guardia), carta_non_posseduta(a, prete)],
            sconosciuta, []),
        reg_evento(C0, carta_scartata(a, guardia),
            conoscenza(_, Info, _, Scarti))
    ->  check(carta_scartata_info,
            \+ member(carta_posseduta(a, guardia), Info)),
        check(carta_scartata_scarti,
            member(guardia, Scarti))
    ;   format('❌ Setup fallito: carta_scartata~n')
    ).


test_carta_vista :-
    (   C0 = conoscenza([a,b], [carta_uguale(a,b)], sconosciuta, []),
        reg_evento(C0, carta_vista(a, principe),
            conoscenza(_, Info, _, _))
    ->  check(carta_vista,
            member(carta_posseduta(a, principe), Info))
    ;   format('❌ Setup fallito: carta_vista~n')
    ).


test_eliminato :-
    (   C0 = conoscenza([a,b], [], sconosciuta, []),
        reg_evento(C0, giocatore_eliminato(a, prete),
            conoscenza(Giocatori, _, _, Scarti))
    ->  check(eliminato_rimosso,
            \+ member(a, Giocatori)),
        check(eliminato_scarto,
            member(prete, Scarti))
    ;   format('❌ Setup fallito: eliminato~n')
    ).


test_autoeliminato :-
    (   C0 = conoscenza([a,b], [], sconosciuta, []),
        reg_evento(C0, giocatore_autoeliminato(a, principessa),
            conoscenza(Giocatori, _, _, Scarti))
    ->  check(autoelim_rimosso,
            \+ member(a, Giocatori)),
        check(autoelim_scarto,
            member(principessa, Scarti))
    ;   format('❌ Setup fallito: autoeliminato~n')
    ).


test_guardia_no_elim :-
    (   C0 = conoscenza([a,b], [], sconosciuta, []),
        reg_evento(C0,
            carta_giocata(a, guardia, b, prete, false),
            conoscenza(_, Info, _, _))
    ->  check(guardia_no_elim,
            member(carta_non_posseduta(prete), Info))
    ;   format('❌ Setup fallito: guardia_no_elim~n')
    ).


test_guardia_elim :-
    (   C0 = conoscenza([a,b], [], sconosciuta, []),
        reg_evento(C0,
            carta_giocata(a, guardia, b, prete, true),
            conoscenza(Giocatori, _, _, Scarti))
    ->  check(guardia_elim_rimozione,
            \+ member(b, Giocatori)),
        check(guardia_elim_scarto,
            member(prete, Scarti))
    ;   format('❌ Setup fallito: guardia_elim~n')
    ).


test_barone_uguaglianza :-
    (   C0 = conoscenza([a,b], [], sconosciuta, []),
        reg_evento(C0,
            carta_giocata(a, barone, b),
            conoscenza(_, Info, _, _))
    ->  check(barone,
            member(carta_uguale(a,b), Info))
    ;   format('❌ Setup fallito: barone~n')
    ).


test_principe :-
    (   C0 = conoscenza([a,b], [], sconosciuta, []),
        reg_evento(C0,
            carta_giocata(a, principe, b, guardia),
            conoscenza(_, _, _, Scarti))
    ->  check(principe,
            member(guardia, Scarti))
    ;   format('❌ Setup fallito: principe~n')
    ).


test_re_scambio :-
    (   C0 = conoscenza([a,b],
            [carta_posseduta(a, guardia)],
            sconosciuta, []),
        reg_evento(C0,
            carta_giocata(a, re, b),
            conoscenza(_, Info, _, _))
    ->  check(re,
            member(carta_posseduta(b, guardia), Info))
    ;   format('❌ Setup fallito: re~n')
    ).


test_contessa :-
    (   C0 = conoscenza([a,b], [], sconosciuta, []),
        reg_evento(C0,
            carta_giocata(a, contessa),
            conoscenza(_, _, _, Scarti))
    ->  check(contessa,
            member(contessa, Scarti))
    ;   format('❌ Setup fallito: contessa~n')
    ).


test_principessa :-
    (   C0 = conoscenza([a,b], [], sconosciuta, []),
        reg_evento(C0,
            carta_giocata(a, principessa, guardia),
            conoscenza(Giocatori, _, _, _))
    ->  check(principessa,
            \+ member(a, Giocatori))
    ;   format('❌ Setup fallito: principessa~n')
    ).

% -------------------------------------------------
% Test concatenazione principe + prete
% a gioca principe su b, poi a gioca prete su c
% verifica scarti e info corrette
% -------------------------------------------------
test_principe_prete :-
    C0 = conoscenza([a,b,c], [], sconosciuta, []),
    reg_eventi(C0,
        [carta_giocata(a, principe, b, guardia),
         carta_giocata(a, prete, c, prete)],
        CF),
    CF = conoscenza(_, _, _, Scarti),
    check(principe_prete_scarti,
        member(guardia, Scarti)),
    check(principe_prete_scarti2,
        member(prete, Scarti)).

% -------------------------------------------------
% Test concatenazione barone + guardia eliminazione
% barone confronta a e b, poi guardia elimina c
% -------------------------------------------------
test_barone_guardia :-
    C0 = conoscenza([a,b,c], [], sconosciuta, []),
    reg_eventi(C0,
        [carta_giocata(a, barone, b),
         carta_giocata(c, guardia, a, principessa, false)],
        CF),
    CF = conoscenza(_, Info, _, _),
    check(barone_guardia_uguaglianza,
        member(carta_uguale(a,b), Info)).

% -------------------------------------------------
% Test concatenazione re + scambio + informazioni multiple
% a gioca re su b, scambio di carte
% -------------------------------------------------
test_re_scambio_cascade :-
    C0 = conoscenza([a,b,c],
        [carta_posseduta(a, guardia), carta_posseduta(b, prete)],
        sconosciuta, []),
    reg_eventi(C0,
        [carta_giocata(a, re, b, guardia, prete),
         carta_giocata(b, contessa)],
        CF),
    CF = conoscenza(_, Info, _, Scarti),
    check(re_scambio_cascade_info1,
        member(carta_posseduta(a, prete), Info)),
    check(re_scambio_cascade_info2,
        member(carta_posseduta(b, guardia), Info)),
    check(re_scambio_cascade_scarti,
        member(contessa, Scarti)).

% -------------------------------------------------
% Test concatenazione principessa + autoeliminazione
% a gioca principessa scartando una carta
% -------------------------------------------------
test_principessa_autoeliminazione :-
    C0 = conoscenza([a,b,c], [], sconosciuta, []),
    reg_eventi(C0,
        [carta_giocata(a, principessa, guardia)],
        CF),
    CF = conoscenza(Giocatori, _, _, _),
    check(principessa_autoelim_rimozione,
        \+ member(a, Giocatori)).

% -------------------------------------------------
% Test concatenazione cancelliere
% a gioca cancelliere vedendo le due carte
% -------------------------------------------------
test_cancellieri_catenati :-
    C0 = conoscenza([a,b,c],
        [carta_posseduta(a, guardia), carta_posseduta(b, prete)],
        sconosciuta, []),
    reg_eventi(C0,
        [carta_giocata(a, cancelliere, guardia, prete, principessa)],
        CF),
    CF = conoscenza(_, Info, _, _),
    check(cancellieri_posizioni,
        member(carta_in_posizione(prete, 2), Info)),
    check(cancellieri_posizioni2,
        member(carta_in_posizione(principessa, 1), Info)).
