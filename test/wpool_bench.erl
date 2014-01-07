-module(wpool_bench).
-author('elbrujohalcon@inaka.net').

-export([run_tasks/3]).

%% @doc Returns the average time involved in processing the small tasks
-spec run_tasks([{small|large, pos_integer()},...], wpool:strategy(), [wpool:option()]) -> float().
run_tasks(TaskGroups, Strategy, Options) ->
    Tasks = lists:flatten([lists:duplicate(N, Type) || {Type, N} <- TaskGroups]),
    {ok, _Pool} = wpool:start_sup_pool(?MODULE, Options),
    try lists:foldl(
            fun (small, Acc) ->
                    {Time, {ok, 0}} =
                        timer:tc(wpool, call, [?MODULE, {erlang, '+', [0,0]}, Strategy, infinity]),
                    [Time/1000|Acc];
                (large, Acc) ->
                    wpool:cast(?MODULE, {timer, sleep, [30000]}, Strategy),
                    Acc
            end, [], Tasks) of
        [] ->
            lager:warning("No times"),
            0.0;
        Times ->
            lager:notice("Times: ~p", [Times]),
            lists:sum(Times) / length(Times)
    after
        wpool:stop_pool(?MODULE)
    end.