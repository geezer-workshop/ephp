-module(ephp_code_test).
-compile(export_all).

-define(CODE_PATH, "../test/code/").

-include_lib("eunit/include/eunit.hrl").

eval(Filename) ->
    case file:read_file(Filename) of
    {ok, Content} ->
        AbsFilename = list_to_binary(filename:absname(Filename)),
        {ok, Ctx} = ephp:context_new(AbsFilename),
        {ok, Output} = ephp_output:start_link(false),
        ephp_context:set_output_handler(Ctx, Output),
        {ok, Ret} = ephp:eval(AbsFilename, Ctx, Content),
        Out = ephp_context:get_output(Ctx),
        ephp_context:destroy_all(Ctx), 
        {ok, Out, Ret};
    Error ->
        Error
    end.

test_code(File) ->
    ?_assert(begin
        try
            {ok, OutCode, _Ret} = eval(?CODE_PATH ++ File ++ ".php"),
            {ok, OutFile} = file:read_file(?CODE_PATH ++ File ++ ".out"),
            ?assertEqual(iolist_to_binary(OutCode), OutFile),
            true
        catch Type:Reason ->
            ?debugFmt("~n\t*** ERROR in ~s.php why: ~p; reason: ~p~n",
                [File, Type, Reason]),
            false
        end
    end).

code_to_test_() ->
    Codes = [
        "empty",
        "array_01",
        "strings_01",
        "template_01",
        "text_op",
        "test_arith",
        "test_concat_number",
        "test_cond",
        "test_date",
        "test_die",
        "test_foreach",
        "test_foreach_break",
        "test_foreach_return",
        "test_for",
        "test_func_in_var",
        "test_function_params",
        "test_function",
        "test_function_refs",
        "test_func_var_dump",
        "test_literal",
        "test_print_true",
        "test_include",
        "test_return_values",
        "test_include_value",
        "test_logic_bnot",
        "test_logic",
        "test_magic_constants",
        "test_minus",
        "test_nested",
        "test_or_die",
        "test_print_r",
        "test_unset",
        "test_include_noparens",
        "test_switch",
        "test_array",
        "test_require",
        "test_string"
    ],
    lists:map(fun(X) -> test_code(X) end, Codes).
