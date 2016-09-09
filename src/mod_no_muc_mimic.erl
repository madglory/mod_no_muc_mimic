%
% Force a user's nickname to match their username when sending any presence messages in group chat.
%
-module(mod_no_muc_mimic).

-behaviour(gen_mod).

-export([
  start/2,
  stop/1,
  on_filter_packet/1,
  mod_opt_type/1
]).

-include("ejabberd.hrl").
-include("logger.hrl").
-include("jlib.hrl").

start(_Host, _Opts) ->
  ?INFO_MSG("Starting mod_no_muc_mimic~n", []),
  ejabberd_hooks:add(filter_packet, global, ?MODULE, on_filter_packet, 0).

stop(_Host) ->
  ejabberd_hooks:delete(filter_packet, global, ?MODULE, on_filter_packet, 0).

on_filter_packet({From, To, {xmlel, <<"presence">>, Attrs, _Els} = Packet} = Msg) ->
    %
    %
    % When we get MUC presence force nickname to user JID.
    %
    %
    MucDomain = get_muc_domain(),
    % leaving a room has type of unavailable, other presence stanzas do not
    % so don't filter leaving messages
    case {To#jid.lserver, lists:keyfind(<<"type">>, 1, Attrs)} of
      {MucDomain, false} ->
        {From, jlib:make_jid(To#jid.luser, To#jid.lserver, From#jid.luser), Packet};
      _ ->
        Msg
    end;
on_filter_packet(Msg) ->
    %
    %
    % Handle the generic case (any packet that isn't of type presence).
    %
    %
    Msg.

get_muc_domain() ->
    gen_mod:get_module_opt(global, ?MODULE, muc_domain, fun iolist_to_binary/1, <<"">>).

mod_opt_type(muc_domain) ->
    fun iolist_to_binary/1;
mod_opt_type(_) ->
    [muc_domain].
