# If there is a rebar in the current directory, use it
ifeq ($(wildcard rebar3),rebar3)
REBAR = $(CURDIR)/rebar3
endif

# And finally, prep to download rebar if all else fails
ifeq ($(REBAR),)
REBAR = $(CURDIR)/rebar3
endif

REBAR_URL = https://s3.amazonaws.com/rebar3/rebar3
REPO=protobuffs

has_eqc := $(shell erl -eval 'try eqc:version(), io:format("true") catch _:_ -> io:format(false) end' -noshell -s init stop)

all: $(REBAR)
	@$(REBAR) compile

compile:
	@$(REBAR) compile

ct:
	./scripts/generate_emakefile.escript
	@$(REBAR) as test ct

eunit:
	@$(REBAR) as test eunit

test: eunit ct

clean:
	@$(REBAR) clean

# Full clean and removal of all build artifacts. Remove deps first to avoid
# wasted effort of cleaning deps before nuking them.
distclean: clean
	@rm -rf _build log .rebar ebin/ $(PROJ).plt
	@find . -name erl_crash.dump -type f -delete

testclean:
	@find log/ct -maxdepth 1 -name ct_run* -type d -cmin +360 -exec rm -fr {} \;
	@find test/*.beam -maxdepth 3 -exec rm -fr {} \;

APPS = kernel stdlib sasl erts ssl tools os_mon runtime_tools crypto inets \
	xmerl webtool snmp public_key mnesia eunit syntax_tools compiler
COMBO_PLT = $(HOME)/.$(REPO)_combo_dialyzer_plt

check_plt: compile
	dialyzer --check_plt --plt $(COMBO_PLT) --apps $(APPS) \
		ebin

build_plt: compile
	dialyzer --build_plt --output_plt $(COMBO_PLT) --apps $(APPS) \
		ebin

dialyzer: compile
	dialyzer -Wno_return --plt $(COMBO_PLT) ebin

$(REBAR):
	curl -Lo rebar3 $(REBAR_URL) || wget $(REBAR_URL)
	chmod a+x rebar3

rebar: $(REBAR)
