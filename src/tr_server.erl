%%% ------------------------------------
%%% @author sion.
%%% @doc
%%% do practice while reading erlang/opt in action 
%%% @end
%%% ------------------------------------

-module(tr_server).

-behaviour(gen_server).

%% API
-export([
	start_link/1,
	start_link/0,
	get_count/0,
	stop/0
	]).

%% gen_server callbacks
-export([
	init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3
	]).

-define(SERVER, ?MODULE).
-define(DEFAULT_PORT, 1055).

-record(state, {port, lsocket, request_count = 0}).

%%% ==================================================
%%% API
%%% ==================================================

start_link(Port) ->
	gen_server:start_link({local, ?SERVER}, ?MODULE, [Port], []).

start_link() ->
	start_link(?DEFAULT_PORT).

get_count() ->
	gen_server:call(?SERVER, get_count).

stop() ->
	gen_server:cast(?SERVER, stop).



%%% ==================================================
%%% gen_server callbacks
%%% ==================================================
init([Port]) ->
	{ok, ListenSocket} = gen_tcp:listen(Port, [{active, true}]),
	{ok, #state{port = Port, lsocket = ListenSocket}, 0}.

handle_call(get_count, _From, State) ->
	{reply, {ok, State#state.request_count}, State}.

handle_cast(stop, State) ->
	{stop, normal, State}.

handle_info({tcp, Socket, RawData}, State) ->
	do_rpc(Socket, RawData),
	ReqCount = State#state.request_count,
	{noreply, State#state{request_count = ReqCount + 1}};
handle_info({tcp_closed, What }, State) ->
	io:format("tcp close ~p ~p ~n ", [What,State]),
	{noreply,State};
handle_info(timeout, #state{lsocket = LSocket} = State) ->
	{ok, _Socket} = gen_tcp:accept(LSocket),
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok,State}.



%%% ==================================================
%%% internal functions
%%% ==================================================
do_rpc(Socket, RawData) ->
	Echo = "you typed " ++ RawData ++ ".",
	gen_tcp:send(Socket, io_lib:fwrite("~p ~n", [Echo])).

