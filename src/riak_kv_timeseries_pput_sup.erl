%% -------------------------------------------------------------------
%%
%% riak_kv_timeseries_pput_sup.erl: Manage poolboy workers for time
%% series parallel put operations
%%
%% Copyright (c) 2015 Basho Technologies, Inc.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

-module(riak_kv_timeseries_pput_sup).
-behaviour(supervisor).

-export([pput/2]).
-export([start_link/2, stop/1]).
-export([init/1]).

-define(POOL_NAME, ts_workers).

start_link(_Type, _Args) ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

stop(_State) ->
    ok.

init([]) ->
    PoolArgs =
        [{name, {local, ?POOL_NAME}},
         {worker_module, riak_kv_timeseries_pput},
         {size, 50},
         {max_overflow, 50}],
    ChildSpec = poolboy:child_spec(?POOL_NAME, PoolArgs, []),

    {ok, {{one_for_one, 10, 10}, [ChildSpec]}}.

pput(Fun, Data) ->
    poolboy:transaction(?POOL_NAME, fun(Worker) ->
        gen_server:call(Worker, {foldl, Fun, Data})
    end).
