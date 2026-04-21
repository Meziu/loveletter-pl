:- use_module('gioco/mazzo'),
use_module(statistica),
use_module('gioco/conoscenza'),
initialization(test).

%write('=== ANALISI: probabilità mano di pippo dopo il gioco di 2 cancellieri ==='), nl,
%C1 = conoscenza([pippo, pluto], [carta_uguale(pippo, pluto), carta_non_posseduta(pippo, principessa)], []),
%reg_eventi(C1, [carta_giocata(pluto, cancelliere, re, barone, prete), carta_giocata(pippo, cancelliere)], C2),
%stampa_probabilita_mano(C2, pippo).

%C1 = conoscenza([pippo, pluto], [carta_uguale(pippo, pluto), carta_non_posseduta(pippo, contessa)], []),
%reg_eventi(C1, [carta_giocata(pluto, cancelliere, re, barone, prete), carta_giocata(pippo, contessa)], C2),
%stampa_probabilita_mano(C2, pippo).

test :-
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
    run_test(test_spia_guardia_chain),
    run_test(test_prete_poi_barone),
    run_test(test_barone_elim_bersaglio),
    run_test(test_barone_autoelim_attaccante),
    run_test(test_principe_su_se_stesso),
    run_test(test_principe_forza_principessa),
    run_test(test_spia_prete_contessa),
    run_test(test_guardia_doppia_mancata),
    run_test(test_principe_poi_guardia_mancata),
    run_test(test_barone_poi_re_semplice),
    run_test(test_domestica_principe_spia),
    run_test(test_cancelliere_scala_posizioni),
    run_test(test_fine_partita),
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
    (   C0 = conoscenza([a, b],
                        [carta_posseduta(a, guardia), carta_non_posseduta(a, prete)], []),
        reg_evento(C0, carta_scartata(a, guardia),
                   conoscenza(_, Info, Scarti))
    ->  check(carta_scartata_info,
              \+ member(carta_posseduta(a, guardia), Info)),
        check(carta_scartata_scarti,
              member(guardia, Scarti))
    ;   format('❌ Setup fallito: carta_scartata~n')
    ).


test_carta_vista :-
    (   C0 = conoscenza([a, b], [carta_uguale(a, b)], []),
        reg_evento(C0, carta_vista(a, principe),
                   conoscenza(_, Info, _))
    ->  check(carta_vista,
              member(carta_posseduta(a, principe), Info))
    ;   format('❌ Setup fallito: carta_vista~n')
    ).


test_eliminato :-
    (   C0 = conoscenza([a, b], [], []),
        reg_evento(C0, giocatore_eliminato(a, prete),
                   conoscenza(Giocatori, _, Scarti))
    ->  check(eliminato_rimosso,
              \+ member(a, Giocatori)),
        check(eliminato_scarto,
              member(prete, Scarti))
    ;   format('❌ Setup fallito: eliminato~n')
    ).


test_autoeliminato :-
    (   C0 = conoscenza([a, b], [], []),
        reg_evento(C0, giocatore_autoeliminato(a, principessa),
                   conoscenza(Giocatori, _, Scarti))
    ->  check(autoelim_rimosso,
              \+ member(a, Giocatori)),
        check(autoelim_scarto,
              member(principessa, Scarti))
    ;   format('❌ Setup fallito: autoeliminato~n')
    ).


test_guardia_no_elim :-
    (   C0 = conoscenza([a, b], [], []),
        reg_evento(C0,
                   carta_giocata(a, guardia, b, prete, false),
                   conoscenza(_, Info, _))
    ->  check(guardia_no_elim,
              member(carta_non_posseduta(b, prete), Info))
    ;   format('❌ Setup fallito: guardia_no_elim~n')
    ).


test_guardia_elim :-
    (   C0 = conoscenza([a, b], [], []),
        reg_evento(C0,
                   carta_giocata(a, guardia, b, prete, true),
                   conoscenza(Giocatori, _, Scarti))
    ->  check(guardia_elim_rimozione,
              \+ member(b, Giocatori)),
        check(guardia_elim_scarto,
              member(prete, Scarti))
    ;   format('❌ Setup fallito: guardia_elim~n')
    ).


test_barone_uguaglianza :-
    (   C0 = conoscenza([a, b], [], []),
        reg_evento(C0,
                   carta_giocata(a, barone, b),
                   conoscenza(_, Info, _))
    ->  check(barone,
              member(carta_uguale(a, b), Info))
    ;   format('❌ Setup fallito: barone~n')
    ).


test_principe :-
    (   C0 = conoscenza([a, b], [], []),
        reg_evento(C0,
                   carta_giocata(a, principe, b, guardia),
                   conoscenza(_, _, Scarti))
    ->  check(principe,
              member(guardia, Scarti))
    ;   format('❌ Setup fallito: principe~n')
    ).


test_re_scambio :-
    (   C0 = conoscenza([a, b],
                        [carta_posseduta(a, guardia)], []),
        reg_evento(C0,
                   carta_giocata(a, re, b),
                   conoscenza(_, Info, _))
    ->  check(re,
              member(carta_posseduta(b, guardia), Info))
    ;   format('❌ Setup fallito: re~n')
    ).


test_contessa :-
    (   C0 = conoscenza([a, b], [], []),
        reg_evento(C0,
                   carta_giocata(a, contessa),
                   conoscenza(_, _, Scarti))
    ->  check(contessa,
              member(contessa, Scarti))
    ;   format('❌ Setup fallito: contessa~n')
    ).


test_principessa :-
    (   C0 = conoscenza([a, b], [], []),
        reg_evento(C0,
                   carta_giocata(a, principessa, guardia),
                   conoscenza(Giocatori, _, _))
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
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, principe, b, guardia),
                carta_giocata(a, prete, c, prete)],
               CF),
    CF = conoscenza(_, _, Scarti),
    check(principe_prete_scarti,
          member(guardia, Scarti)),
    check(principe_prete_scarti2,
          member(prete, Scarti)).

% -------------------------------------------------
% Test concatenazione barone + guardia eliminazione
% barone confronta a e b, poi guardia elimina c
% -------------------------------------------------
test_barone_guardia :-
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, barone, b),
                carta_giocata(c, guardia, a, principessa, false)],
               CF),
    CF = conoscenza(_, Info, _),
    check(barone_guardia_uguaglianza,
          member(carta_uguale(a, b), Info)).

% -------------------------------------------------
% Test concatenazione re + scambio + informazioni multiple
% a gioca re su b, scambio di carte
% -------------------------------------------------
test_re_scambio_cascade :-
    C0 = conoscenza([a, b, c],
                    [carta_posseduta(a, guardia), carta_posseduta(b, prete)], []),
    reg_eventi(C0,
               [carta_giocata(a, re, b, guardia, prete),
                carta_giocata(b, contessa)],
               CF),
    CF = conoscenza(_, Info, Scarti),
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
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, principessa, guardia)],
               CF),
    CF = conoscenza(Giocatori, _, _),
    check(principessa_autoelim_rimozione,
          \+ member(a, Giocatori)).

% -------------------------------------------------
% Test concatenazione cancelliere
% a gioca cancelliere vedendo le due carte
% -------------------------------------------------
test_cancellieri_catenati :-
    C0 = conoscenza([a, b, c],
                    [carta_posseduta(a, guardia), carta_posseduta(b, prete)], []),
    reg_eventi(C0,
               [carta_giocata(a, cancelliere, guardia, prete, principessa)],
               CF),
    CF = conoscenza(_, Info, _),
    check(cancellieri_posizioni,
          member(carta_in_posizione(prete, 2), Info)),
    check(cancellieri_posizioni2,
          member(carta_in_posizione(principessa, 1), Info)).

% -------------------------------------------------
% Test: spia + guardia mancata sullo stesso bersaglio
% a gioca spia, b gioca guardia su c indovinando prete (sbaglia)
% -------------------------------------------------
test_spia_guardia_chain :-
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, spia),
                carta_giocata(b, guardia, c, prete, false)],
               CF),
    CF = conoscenza(_, Info, Scarti),
    check(spia_guardia_spia_in_scarti,
          member(spia, Scarti)),
    check(spia_guardia_non_posseduta,
          member(carta_non_posseduta(c, prete), Info)).

% -------------------------------------------------
% Test: prete rivela carta, poi barone conferma uguaglianza
% a gioca prete su b e vede guardia, poi a gioca barone su b
% -------------------------------------------------
test_prete_poi_barone :-
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, prete, b, guardia),
                carta_giocata(a, barone, b)],
               CF),
    CF = conoscenza(_, Info, Scarti),
    check(prete_barone_prete_in_scarti,
          member(prete, Scarti)),
    check(prete_barone_uguale,
          member(carta_uguale(a, b), Info)).

% -------------------------------------------------
% Test: barone con eliminazione del bersaglio
% a gioca barone su b, b viene eliminato con guardia (valore 1)
% vincitore a → carta_superiore(a, 1)
% -------------------------------------------------
test_barone_elim_bersaglio :-
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, barone, b, b, guardia)],
               CF),
    CF = conoscenza(Giocatori, Info, Scarti),
    check(barone_elim_b_rimosso,
          \+ member(b, Giocatori)),
    check(barone_elim_guardia_scartata,
          member(guardia, Scarti)),
    check(barone_elim_superiore_a,
          member(carta_superiore(a, 1), Info)).

% -------------------------------------------------
% Test: barone con autoeliminazione dell'attaccante
% a gioca barone su b, a viene eliminato con prete (valore 2)
% vincitore b → carta_superiore(b, 2)
% -------------------------------------------------
test_barone_autoelim_attaccante :-
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, barone, b, a, prete)],
               CF),
    CF = conoscenza(Giocatori, Info, Scarti),
    check(barone_autoelim_a_rimosso,
          \+ member(a, Giocatori)),
    check(barone_autoelim_prete_scartato,
          member(prete, Scarti)),
    check(barone_autoelim_superiore_b,
          member(carta_superiore(b, 2), Info)).

% -------------------------------------------------
% Test: principe giocato su se stesso
% a gioca principe su a stesso, scartando prete
% -------------------------------------------------
test_principe_su_se_stesso :-
    C0 = conoscenza([a, b], [], []),
    reg_eventi(C0,
               [carta_giocata(a, principe, a, prete)],
               CF),
    CF = conoscenza(_, _, Scarti),
    check(principe_self_prete_in_scarti,
          member(prete, Scarti)).

% -------------------------------------------------
% Test: principe forza lo scarto della principessa → eliminazione
% a gioca principe su b, b scarta principessa ed è eliminato
% -------------------------------------------------
test_principe_forza_principessa :-
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, principe, b, principessa)],
               CF),
    CF = conoscenza(Giocatori, _, _),
    check(principe_principessa_b_eliminato,
          \+ member(b, Giocatori)).

% -------------------------------------------------
% Test: due guardie mancate accumulano carta_non_posseduta distinte
% a e c giocano guardia su b sbagliando carte diverse
% -------------------------------------------------
test_guardia_doppia_mancata :-
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, guardia, b, prete, false),
                carta_giocata(c, guardia, b, barone, false)],
               CF),
    CF = conoscenza(_, Info, _),
    check(guardia_doppia_non_prete,
          member(carta_non_posseduta(b, prete), Info)),
    check(guardia_doppia_non_barone,
          member(carta_non_posseduta(b, barone), Info)).

% -------------------------------------------------
% Test: prete rivela carta, poi guardia usa quella info per eliminare
% a gioca prete su b e vede prete (b ha prete), poi c gioca guardia su b
% indovinando prete → b eliminato
% Nota: CartaScelta = prete \== guardia ✓
% -------------------------------------------------
test_prete_poi_guardia_elim :-
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, prete, b, prete),
                carta_giocata(c, guardia, b, prete, true)],
               CF),
    CF = conoscenza(Giocatori, _, Scarti),
    check(prete_guardia_b_rimosso,
          \+ member(b, Giocatori)),
    check(prete_guardia_prete_in_scarti,
          member(prete, Scarti)).

% -------------------------------------------------
% Test: spia + prete + contessa in sequenza su tre giocatori
% verifica scarti e che carta_posseduta sopravviva alla contessa
% -------------------------------------------------
test_spia_prete_contessa :-
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, spia),
                carta_giocata(b, prete, c, barone),
                carta_giocata(c, contessa)],
               CF),
    CF = conoscenza(_, Info, Scarti),
    check(spc_spia_scartata,
          member(spia, Scarti)),
    check(spc_prete_scartato,
          member(prete, Scarti)),
    check(spc_contessa_scartata,
          member(contessa, Scarti)),
    check(spc_c_possiede_barone,
          member(carta_posseduta(c, barone), Info)).

% -------------------------------------------------
% Test: principe + guardia mancata sullo stesso bersaglio
% a gioca principe su b (b scarta barone), poi c gioca guardia su b sbagliando
% verifica barone in scarti + carta_non_posseduta + carta_non_posseduta(a, contessa)
% -------------------------------------------------
test_principe_poi_guardia_mancata :-
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, principe, b, barone),
                carta_giocata(c, guardia, b, prete, false)],
               CF),
    CF = conoscenza(_, Info, Scarti),
    check(ppgm_barone_in_scarti,
          member(barone, Scarti)),
    check(ppgm_non_contessa_a,
          member(carta_non_posseduta(a, contessa), Info)),
    check(ppgm_non_prete_b,
          member(carta_non_posseduta(b, prete), Info)).

% -------------------------------------------------
% Test: barone (vince a) poi re semplice (a scambia con c)
% carta_superiore(a, 1) viene rimossa da carta_scartata(a, re) (re vale 7 >= 1)
% ma carta_non_posseduta(a, contessa) viene aggiunta e scambiata → carta_non_posseduta(c, contessa)
% -------------------------------------------------
test_barone_poi_re_semplice :-
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, barone, b, b, guardia),
                carta_giocata(a, re, c)],
               CF),
    CF = conoscenza(Giocatori, Info, _),
    check(bpr_b_rimosso,
          \+ member(b, Giocatori)),
    check(bpr_non_contessa_trasferita_a_c,
          member(carta_non_posseduta(c, contessa), Info)).

% -------------------------------------------------
% Test: cancelliere pieno + cancelliere semplice scalano le posizioni
% a gioca cancelliere tenendo guardia (prete pos 2, barone pos 1)
% b gioca cancelliere semplice → posizioni incrementate di 2
% risultato atteso: prete pos 4, barone pos 3
% -------------------------------------------------
test_cancelliere_scala_posizioni :-
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, cancelliere, guardia, prete, barone),
                carta_giocata(b, cancelliere)],
               CF),
    CF = conoscenza(_, Info, _),
    check(cancelliere_scala_prete,
          member(carta_in_posizione(prete, 4), Info)),
    check(cancelliere_scala_barone,
          member(carta_in_posizione(barone, 3), Info)).

% -------------------------------------------------
% Test: re con carte note + contessa sul giocatore che ha ricevuto la carta
% a ha guardia, b ha prete; a scambia con b (a ottiene prete, b ottiene guardia)
% poi b gioca contessa
% -------------------------------------------------
test_re_noto_poi_contessa :-
    C0 = conoscenza([a, b, c],
                    [carta_posseduta(a, guardia), carta_posseduta(b, prete)], []),
    reg_eventi(C0,
               [carta_giocata(a, re, b, guardia, prete),
                carta_giocata(b, contessa)],
               CF),
    CF = conoscenza(_, Info, Scarti),
    check(rnpc_a_ha_prete,
          member(carta_posseduta(a, prete), Info)),
    check(rnpc_contessa_scartata,
          member(contessa, Scarti)).

% -------------------------------------------------
% Test: domestica + principe + spia (tre carte semplici in fila)
% verifica che tutti e tre i valori siano in scarti
% -------------------------------------------------
test_domestica_principe_spia :-
    C0 = conoscenza([a, b, c], [], []),
    reg_eventi(C0,
               [carta_giocata(a, domestica),
                carta_giocata(b, principe, c, prete),
                carta_giocata(a, spia)],
               CF),
    CF = conoscenza(_, _, Scarti),
    check(dps_domestica,
          member(domestica, Scarti)),
    check(dps_principe,
          member(principe, Scarti)),
    check(dps_prete,
          member(prete, Scarti)),
    check(dps_spia,
          member(spia, Scarti)).

test_fine_partita:-
    C = conoscenza([pippo, pluto, paperino], [carta_non_posseduta(paperino, barone), carta_non_posseduta(pippo, contessa)], [guardia, guardia, principe, spia, spia, guardia, re, barone, principe, guardia, guardia, cancelliere, cancelliere, domestica, domestica, contessa, guardia]),
    check(fine_partita_a_3, fine_partita(C)).
