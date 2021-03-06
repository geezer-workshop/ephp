all: ephp

force-deps:
	./rebar get-deps
	./rebar update-deps
	./rebar compile

deps:
	./rebar get-deps
	./rebar compile

compile: deps
	./rebar compile skip_deps=true

test: deps
	./rebar eunit skip_deps=true

ephp: compile
	./rebar escriptize skip_deps=true

.PHONY: test compile force-deps all

