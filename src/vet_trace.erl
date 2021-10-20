%% @doc
%% `vet_trace'
-module(vet_trace).
-author('Serge - github.com/sunneach').
-vsn('0.0.1').
-export([trace/1, trace/2, trace/3, trace/4, stop/0]).

%% @doc trace all calls to module Mod
%% showing all trace records
trace(Mod) when is_atom(Mod) ->
    trace({Mod,'_','_'}, -1);
%% @doc trace all calls to (Mod, F, A)
%% showing all trace records
trace({Mod, F, A}) when is_atom(Mod), is_atom(F), A =:= '_' orelse is_integer(A) -> 
    trace({Mod,F,A}, -1);
%% @doc trace messages to and from Pid
%% showing all trace records
trace(Pid) when is_pid(Pid) ->
    trace(Pid, -1).

%% @doc trace all calls to Mod
%% using matchspec Ms
%% showing all trace records
trace(Mod, Ms) when is_atom(Mod), is_list(Ms)
    -> trace({Mod,'_','_'},Ms,-1);
%% @doc trace all calls to (Mod, F, A)
%% using match spec Ms
%% showing all trace records
trace({Mod, F, A},Ms) when is_atom(Mod),
                         is_atom(F),
                         is_integer(A) orelse A =:= '_',
                         is_list(Ms) ->
    trace({Mod, F, A},Ms,-1);
%% @doc trace all calls to Mod
%% and all message traffic to and from Pid
%% showing all trace records
trace(Mod, Pid) when is_atom(Mod), is_pid(Pid) ->
    trace({Mod, '_', '_'}, Pid, -1);
%% @doc trace all calls to Mod
%% showing Max trace records
trace(Mod, Max) when is_atom(Mod), is_integer(Max) ->
    trace({Mod,'_','_'}, Max);

%% @doc trace all calls to (Mod, F, A)
%% showing Max trace records
trace({Mod, F, A}, Max) when is_atom(Mod),
                             is_atom(F),
                             A =:= '_' orelse is_integer(A),
                             is_integer(Max) -> 
    Rcv = start_link(Max, {Mod, F, A}),
    trace_module({Mod, F, A}, Rcv);
%% @doc trace messages to and from Pid
%% showing Max trace records
trace(Pid, Max) when is_pid(Pid), is_integer(Max) ->
    Rcv = start_link(Max, Pid),
    trace_process(Pid, Rcv);
%% @doc trace all calls to {Mod,F,A}
%% and all message traffic to and from Pid
%% showing all trace records
trace({Mod, F, A}, Pid) when is_pid(Pid) ->
    trace({Mod, F, A}, Pid, -1).

%% @doc trace all calls to Mod
%% using match spec Ms
%% and all message traffic to and from Pid
%% showing all trace records
trace(Mod, Ms, Pid) when is_atom(Mod), is_list(Ms), is_pid(Pid) ->
    trace({Mod,'_','_'}, Ms, Pid, -1);
%% @doc trace all calls to Mod
%% and all message traffic to and from Pid
%% showing Max trace records
trace(Mod, Pid, Max) when is_atom(Mod), is_pid(Pid), is_integer(Max) ->
    trace({Mod,'_','_'}, Pid, Max);
%% @doc trace all calls to {Mod,F,A}
%% and all message traffic to and from Pid
%% showing Max trace records
trace({Mod, F, A}, Pid, Max) 
      when is_atom(Mod),
           is_atom(F),
           A=:='_' orelse is_integer(A),
           is_pid(Pid),
           is_integer(Max) ->
    Rcv = start_link(Max, {Mod,Pid}),
    trace_process(Pid, Rcv),
    trace_module({Mod,F,A}, Rcv);
%% @doc trace all calls to Mod
%% using match spec Ms
%% showing Max trace records
trace(Mod, Ms, Max) when is_atom(Mod),
                      is_list(Ms),
                      is_integer(Max) ->
    trace({Mod,'_','_'}, Ms, Max);
%% @doc trace all calls to {Mod,F,A}
%% using match spec Ms
%% and all message traffic to and from Pid
%% showing all trace records
trace({Mod, F, A}, Ms, Pid) when is_list(Ms), is_pid(Pid) ->
    trace({Mod, F, A}, Ms, Pid, -1);
%% @doc trace all calls to {Mod,F,A}
%% using match spec Ms
%% showing Max trace records
trace({Mod, F, A}, Ms, Max) when
                      is_atom(Mod),
                      is_atom(F),
                      A =:= '_' orelse is_integer(A),
                      is_list(Ms),
                      is_integer(Max) ->
    Rcv = start_link(Max, {Mod,F,A}),
    trace_module({Mod,F,A},Ms, Rcv).

%% @doc trace all calls to Mod
%% using match spec Ms
%% and all message traffic to and from Pid
%% showing Max trace records
trace(Mod, Ms, Pid, Max) when is_atom(Mod),
                              is_list(Ms),
                              is_pid(Pid), is_integer(Max) ->
     trace({Mod, '_', '_'}, Ms, Pid, Max);
%% @doc trace all calls to {Mod,F,A}
%% using match spec Ms
%% and all message traffic to and from Pid
%% showing Max trace records
trace({Mod, F, A}, Ms, Pid, Max) when is_atom(Mod),
                                    is_atom(F),
                                    A =:= '_' orelse is_integer(A),
                                    is_list(Ms),
                                    is_pid(Pid),
                                    is_integer(Max) ->
    Rcv = start_link(Max, {{Mod,F,A},Pid}),
    trace_process(Pid, Rcv),
    trace_module({Mod,F,A}, Ms, Rcv).

%% @doc trace 
%% message traffic to and from Pid
trace_process(Pid, Rcv) when is_pid(Pid), is_pid(Rcv) ->
    trace_process(Pid, Rcv, is_app_alive(Pid)).

%% @doc trace 
%% message traffic to and from Pid
%% when Pid is alive
trace_process(Pid, Rcv, true) ->
    erlang:trace(Pid, true, [send,      {tracer, Rcv},
                             'receive', {tracer, Rcv}]);

%% @doc trace 
%% message traffic to and from Pid
%% when Pid is not alive
trace_process(Pid, _Rcv, false) ->
    io:format("cannot trace stopped Pid: ~p~n",[Pid]).
    
%% @doc trace all calls to {Mod,F,A}
%% using receiver Rcv
%% showing return values and exceptions
trace_module({Mod, F, A}, Rcv) when is_pid(Rcv) ->
    erlang:trace_pattern({Mod,F,A},
                         [{'_', [],[
                                    {return_trace},
                                    {exception_trace}
                                   ]}],
                                   [local]),
    erlang:trace(all, true, [call, {tracer, Rcv}]).

%% @doc trace all calls to {Mod,F,A}
%% using match spec Ms and receiver Rcv
trace_module({Mod, F, A}, Ms, Rcv) when is_list(Ms),
                                      is_pid(Rcv) ->
    erlang:trace_pattern({Mod,F,A},Ms,[local]),
    erlang:trace(all, true, [call, {tracer, Rcv}]).

%% @doc stop all tracing
stop() ->
    IsTracerRegistered = whereis(vet_tracer) =/= undefined,
    stop(IsTracerRegistered).

%% @doc stop all tracing
%% when tracer is stopped
stop(false) -> already_stopped; %% vet_tracer is not registered
%% @doc stop all tracing
%% when tracer is active
stop(true) ->                   %% vet_tracer is registered
    vet_tracer ! {self(),stop},
    receive
        stopped -> 
            io:format("vet_tracer stopped~n")
    after 100 -> 
            error("vet_tracer is non-responsive~n")
    end.

%% @doc stop all App pid tracing
stop_trace(App) when is_pid(App) ->
    stop_trace_process(App, is_app_alive(App));
%% @doc stop Mod tracing
stop_trace(Mod) when is_atom(Mod) or is_tuple(Mod) ->
    erlang:trace(all, false, [call]),
    erlang:trace_pattern({'_', '_', '_'}, false, [local]),
    io:format("tracing of ~p stopped.~n",[Mod]);
%% @doc stop all tracing
%% of Mod calls and Pid messages
stop_trace({Mod, Pid}) when is_atom(Mod),is_pid(Pid) ->
    stop_trace(Mod),
    stop_trace(Pid).

%% @doc stop all tracing
%% of App pid messages when App is alive
stop_trace_process(App, true) ->  %% App is alive
    erlang:trace(all, false, [all]),
    io:format("tracing of process ~p stopped.~n",[App]).

%% @doc start receiver for Mod trace, accepting Max records
%% of a single event
start_link(Max, Mod) ->
    spawn_link(fun()
               -> init(Max,Max,Mod) end).

init(Max, Max, Obj) ->
    IsVetAlive = is_vet_alive(),
    init(Max, Max, Obj, IsVetAlive).

init(_, _, _, true) ->
    error("need vet_trace:stop() first");
init(Max, Max, Obj, false) ->
    register(vet_tracer,self()),
    process_flag(trap_exit, true),
    loop(Max, Max, Obj).
    

loop(Count, Max, Obj) when is_integer(Max),
                      is_integer(Count),
                      Count =:= 0 -> 
    io:format("limit of ~p records reached.~n",[Max]),
    sleep(200),
    flush(),
    loop(Max, Max, Obj);
loop(Count, Max, Obj) when is_integer(Count),
                      is_integer(Max),
                      Max =/= 0 ->
    receive 
        {From,stop} -> stop_trace(Obj),
                       From ! stopped;
        Msg  -> output(Msg),
                loop(Count-1,Max, Obj)
    end.

%% --------- utility ----------

%% @doc sleep Time milliseconds
sleep(Time) ->
    receive after Time -> ok end.

%% @doc flush the inbox
flush() ->
    receive _M -> flush()
    after 0 -> ok
    end.

%% @doc check the tracer status
is_vet_alive() ->
    Vet_Pid = whereis(vet_tracer),
    is_app_alive(Vet_Pid).

%% @doc check the process status
is_app_alive(App) when is_pid(App)->
    erlang:process_info(App) =/= undefined;
is_app_alive(_) -> false.

%% @doc output trace records
output({trace,Pid,call,{Mod,Fun,Args}}) -> 
   io:format("~s ~p ~p:~p", [tmstamp(),
                             Pid,
                             Mod,
                             Fun]),
   repr(Args);
output({trace,Pid,'receive',Msg}) -> 
   io:format("~s ~p << ~p ~n",[tmstamp(), Pid, Msg]);
output({trace,Pid,return_from,{Mod,Fun,Arity},Value}) -> 
   io:format("~s ~p ~p:~p/~p ==> ~p~n",[tmstamp(),
                                        Pid,
                                        Mod,
                                        Fun,
                                        Arity,
                                        Value]);
output({trace,Pid,exception_from,{Mod,Fun,Arity},Value}) -> 
   io:format("~s ~p ~p:~p/~p ==> Error: ~p~n",[tmstamp(),
                                        Pid,
                                        Mod,
                                        Fun,
                                        Arity,
                                        Value]);
output({trace,Pid,send,Msg,Dest}) -> 
   io:format("~s ~p ~p >> ~p~n", [tmstamp(),
                                  Pid,
                                  Msg,
                                  Dest]);
output(Msg) -> 
   io:format("~s ~p~n",[tmstamp(),Msg]).

tmstamp() -> calendar:system_time_to_rfc3339(
                    erlang:system_time(microsecond),
                    [{unit, microsecond},
                     {time_designator, $\s}]).

repr([]) -> io:format("()~n");
repr(Args) -> repr(Args,1).

repr([H|T],Pos) when Pos > 1->
    io:format(",~p",[H]),
    repr(T, Pos+1);
repr([H|T],Pos) when Pos == 1->
    io:format("(~p",[H]),
    repr(T, Pos+1);
repr([],_)->
    io:format(")~n").
