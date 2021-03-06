-module(ephp_func_vars).
-compile([warnings_as_errors]).

-behaviour(ephp_func).

-export([
    init/0,
    is_array/2,
    is_bool/2,
    is_integer/2,
    print_r/2,
    var_dump/2,
    print_r/3,
    isset/2,
    empty/2,
    gettype/2,
    unset/2
]).

-include("ephp.hrl").

-define(SPACES, "    ").
-define(SPACES_VD, "  ").

-spec init() -> [ephp_func:php_function()].

init() -> [
    is_array, is_bool, is_integer, print_r, isset, empty, gettype, unset,
    var_dump
].

-spec is_array(Context :: context(), Value :: var_value()) -> boolean().

is_array(_Context, {_,Value}) when ?IS_DICT(Value) -> 
    true;

is_array(_Context, _Value) -> 
    false.

-spec is_bool(Context :: context(), Value :: var_value()) -> boolean().

is_bool(_Context, {_,Value}) when is_boolean(Value) -> 
    true;

is_bool(_Context, _Value) -> 
    false.

-spec is_integer(Context :: context(), Value :: var_value()) -> boolean().

is_integer(_Context, {_,Value}) when is_integer(Value) ->
    true;

is_integer(_Context, _Value) ->
    false.

-spec print_r(Context :: context(), Value :: var_value()) -> true | binary().

print_r(_Context, {_,Value}) when not ?IS_DICT(Value) -> 
    ephp_util:to_bin(Value);

print_r(Context, Value) ->
    print_r(Context, Value, {false,false}).


-spec var_dump(Context :: context(), Value :: var_value()) -> null.

var_dump(Context, {_,Value}) ->
    Result = case var_dump_fmt(Context, Value, <<?SPACES_VD>>) of
    Elements when is_list(Elements) ->
        Data = lists:foldl(fun(Chunk,Total) ->
            <<Total/binary, Chunk/binary>>
        end, <<>>, Elements),
        Size = ephp_util:to_bin(length(Value)),
        if ?IS_DICT(Value) ->
            <<"array(", Size/binary, ") {\n", Data/binary, "}\n">>;
        true ->
            Data
        end;
    Element ->
        Element
    end,
    ephp_context:set_output(Context, Result), 
    null.

-spec print_r(Context :: context(), Value :: var_value(), Output :: boolean()) -> true | binary().

print_r(_Context, {_,Value}, {_,true}) when not ?IS_DICT(Value) -> 
    ephp_util:to_bin(Value);

print_r(Context, {_,Value}, {_,false}) when not ?IS_DICT(Value) -> 
    ephp_context:set_output(Context, ephp_util:to_bin(Value)),
    true;

print_r(Context, {_,Value}, {_,true}) ->
    Data = lists:foldl(fun(Chunk,Total) ->
        <<Total/binary, Chunk/binary>>
    end, <<>>, print_r_fmt(Context, Value, <<?SPACES>>)),
    <<"Array\n(\n", Data/binary, ")\n">>;

print_r(Context, {_,Value}, {_,false}) ->
    Data = lists:foldl(fun(Chunk,Total) ->
        <<Total/binary, Chunk/binary>>
    end, <<>>, print_r_fmt(Context, Value, <<?SPACES>>)),
    ephp_context:set_output(Context, <<"Array\n(\n", Data/binary, ")\n">>),
    true.

-spec isset(Context :: context(), Value :: var_value()) -> boolean().

isset(_Context, {_,Value}) ->
    case Value of
        undefined -> false;
        _ -> true
    end.

-spec empty(Context :: context(), Value :: var_value()) -> boolean().

empty(_Context, {_,Value}) ->
    case Value of
        undefined -> true;
        <<"0">> -> true;
        <<>> -> true;
        false -> true;
        _ -> false
    end.

-spec gettype(Context :: context(), Value :: var_value()) -> binary().

gettype(_Context, {_,Value}) when is_boolean(Value) -> <<"boolean">>;
gettype(_Context, {_,Value}) when is_integer(Value) -> <<"integer">>;
gettype(_Context, {_,Value}) when is_float(Value) -> <<"double">>;
gettype(_Context, {_,Value}) when is_binary(Value) -> <<"string">>;
gettype(_Context, {_,Value}) when ?IS_DICT(Value) -> <<"array">>;
%% TODO: object type
%% TODO: resource type
gettype(_Context, {_,null}) -> <<"NULL">>;
gettype(_Context, {_,_}) -> <<"unknown type">>.

-spec unset(Context :: context(), Var :: var_value()) -> null.

unset(Context, {Var,_}) ->
    ephp_context:set(Context, Var, undefined),
    null. 

%% ----------------------------------------------------------------------------
%% Internal functions
%% ----------------------------------------------------------------------------

var_dump_fmt(Context, {var_ref,VarPID,VarRef}, Spaces) ->
    %% FIXME add recursion control
    Var = ephp_vars:get(VarPID, VarRef),
    var_dump_fmt(Context, Var, Spaces);

var_dump_fmt(_Context, true, _Spaces) ->
    <<"bool(true)\n">>;

var_dump_fmt(_Context, false, _Spaces) ->
    <<"bool(false)\n">>;

var_dump_fmt(_Context, Value, _Spaces) when is_integer(Value) -> 
    <<"int(",(ephp_util:to_bin(Value))/binary, ")\n">>;

var_dump_fmt(_Context, Value, _Spaces) when is_float(Value) -> 
    <<"double(",(ephp_util:to_bin(Value))/binary, ")\n">>;

var_dump_fmt(_Context, Value, _Spaces) when is_binary(Value) -> 
    Size = ephp_util:to_bin(byte_size(Value)),
    <<"string(",Size/binary,") \"",(ephp_util:to_bin(Value))/binary, "\"\n">>;

var_dump_fmt(Context, Value, Spaces) ->
    ?DICT:fold(fun(Key, Val, Res) ->
        KeyBin = if
            not is_binary(Key) -> ephp_util:to_bin(Key);
            true -> <<"\"", Key/binary, "\"">>
        end,
        Res ++ case var_dump_fmt(Context, Val, <<Spaces/binary, ?SPACES_VD>>) of
            V when is_binary(V) -> 
                [
                    <<Spaces/binary, "[", KeyBin/binary, "] =>\n",
                        Spaces/binary, V/binary>>
                ];
            V when is_list(V) ->
                Elements = ephp_util:to_bin(length(Val)),
                [
                    <<Spaces/binary, "[", KeyBin/binary, "] =>\n">>,
                    <<Spaces/binary,"array(", Elements/binary, ") {\n">>
                ] ++ V ++ [
                    <<Spaces/binary, "}\n">>
                ]
        end
    end, [], Value).

print_r_fmt(Context, {var_ref,VarPID,VarRef}, Spaces) ->
    %% FIXME add recursion control
    Var = ephp_vars:get(VarPID, VarRef),
    print_r_fmt(Context, Var, Spaces);

print_r_fmt(_Context, Value, _Spaces) when not ?IS_DICT(Value) -> 
    <<(ephp_util:to_bin(Value))/binary, "\n">>;

print_r_fmt(Context, Value, Spaces) ->
    ?DICT:fold(fun(Key, Val, Res) ->
        KeyBin = ephp_util:to_bin(Key),
        Res ++ case print_r_fmt(Context, Val, <<Spaces/binary, ?SPACES>>) of
            V when is_binary(V) -> 
                [<<Spaces/binary, "[", KeyBin/binary, "] => ", V/binary>>];
            V when is_list(V) ->
                Content = lists:map(fun(Element) ->
                    <<Spaces/binary, Element/binary>>
                end, V),
                [
                    <<Spaces/binary, "[", KeyBin/binary, "] => Array\n">>, 
                    <<Spaces/binary, "(\n">>
                ] ++ Content ++ [
                    <<Spaces/binary, ")\n">>
                ]
        end
    end, [], Value).
