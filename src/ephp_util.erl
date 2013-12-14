-module(ephp_util).
-compile([warnings_as_errors]).

-export([
    to_bin/1,
    increment_code/1,
    zero_if_undef/1
]).

-include("ephp.hrl").

-spec to_bin(A :: binary() | string() | integer() | undefined) -> binary().

to_bin(A) when is_binary(A) ->
    A; 

to_bin(A) when is_list(A) -> 
    list_to_binary(A);  

to_bin(A) when is_integer(A) -> 
    to_bin(integer_to_list(A)); 

to_bin(A) when is_float(A) -> 
    to_bin(float_to_list(A));

to_bin(true) -> <<"1">>;

to_bin(false) -> <<>>;

to_bin(undefined) -> <<>>. 


-spec increment_code(Code :: binary()) -> integer() | binary().

increment_code(<<>>) ->
    1;

increment_code(Code) when is_binary(Code) ->
    S = byte_size(Code) - 1,
    <<H:S/binary,T:8/integer>> = Code,
    if
        (T >= $a andalso T < $z) orelse
        (T >= $A andalso T < $Z) orelse
        (T >= $0 andalso T < $9) -> 
            <<H/binary,(T+1):8/integer>>;
        T =:= $z andalso H =/= <<>> ->
            NewH = increment_code(H),
            <<NewH/binary, "a">>;
        T =:= $z ->
            <<"aa">>;
        T =:= $Z andalso H =/= <<>> ->
            NewH = increment_code(H),
            <<NewH/binary, "A">>;
        T =:= $Z ->
            <<"AA">>;
        T =:= $9 andalso H =/= <<>> ->
            NewH = increment_code(H),
            <<NewH/binary, "0">>;
        T =:= $9 ->
            <<"10">>;
        true ->
            <<H/binary, T:8/integer>>
    end.


-spec zero_if_undef(Value :: undefined | 
    dict() | integer() | float() | string() | binary()) -> integer().

zero_if_undef(undefined) -> 0;

zero_if_undef(Value) when ?IS_DICT(Value) -> throw(einvalidop);

zero_if_undef(Value) when not is_number(Value) -> 0;

zero_if_undef(Value) -> Value.
