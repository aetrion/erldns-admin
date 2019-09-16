%% Copyright (c) 2012-2019, DNSimple Corporation 
%%
%% Permission to use, copy, modify, and/or distribute this software for any
%% purpose with or without fee is hereby granted, provided that the above
%% copyright notice and this permission notice appear in all copies.
%%
%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%% WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%% MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
%% ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
%% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

%% @doc Cowbow handler that handles Admin API requests to /zones/:name
-module(erldns_admin_zone_resource_handler).

-export([init/2]).
-export([content_types_provided/2, is_authorized/2, resource_exists/2, allowed_methods/2, delete_resource/2]).
-export([to_html/2, to_json/2, to_text/2]).

-behaviour(cowboy_rest).

-include_lib("dns_erlang/include/dns.hrl").
-include_lib("erldns/include/erldns.hrl").

init(Req, State) ->
  {cowboy_rest, Req, State}.

allowed_methods(Req, State) ->
  {[<<"GET">>, <<"DELETE">>], Req, State}.

content_types_provided(Req, State) ->
  {[
      {<<"text/html">>, to_html},
      {<<"text/plain">>, to_text},
      {<<"application/json">>, to_json}
    ], Req, State}.

is_authorized(Req, State) ->
  erldns_admin:is_authorized(Req, State).

resource_exists(Req, State) ->
  {Name, _} = cowboy_req:binding(name, Req),
  {erldns_zone_cache:in_zone(Name), Req, State}.

delete_resource(Req, State) ->
  {Name, _} = cowboy_req:binding(name, Req),
  lager:debug("Received DELETE for ~p", [Name]),
  erldns_zone_cache:delete_zone(Name),
  {true, Req, State}.


to_html(Req, State) ->
  {<<"erldns admin">>, Req, State}.

to_text(Req, State) ->
  {<<"erldns admin">>, Req, State}.

to_json(Req, State) ->
  {Name, _} = cowboy_req:binding(name, Req),
  lager:debug("Received GET for ~p", [Name]),
  case erldns_zone_cache:get_zone_with_records(Name) of
    {ok, Zone} ->
      {erldns_zone_encoder:zone_to_json(Zone), Req, State};
    {error, Reason} ->
      lager:error("Error getting zone: ~p", [Reason]),
      {ok, Req2} = cowboy_req:reply(400, [], io_lib:format("Error getting zone: ~p", [Reason]), Req),
      {halt, Req2, State}
  end.
