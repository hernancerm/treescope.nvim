HELP_FILE := ./doc/treescope.txt
CMD_NVIM := nvim --headless --noplugin
ECHASNOVSKI_GH_BASE_URL := https://raw.githubusercontent.com/echasnovski
NVIM_TREESITTER_GH_BASE_URL := https://github.com/nvim-treesitter/nvim-treesitter
CMD_MINI_DOC_GENERATE := @$(CMD_NVIM) -u ./scripts/minidoc_init.lua && echo ''
MINI_DOC_GIT_HASH := eb61bebe1d2b96835b1b67bb6e600cfc69ae4ad2
MINI_TEST_GIT_HASH := 22f98a71ca0a05e67cddcab9e476e8e0af6a8c19
NVIM_TREESITTER_GIT_HASH := 4967fa48b0fe7a7f92cee546c76bb4bb61bb14d5
STYLUA_VERSION := $(shell grep stylua .tool-versions | awk '{ print $$2 }')
STYLUA := $(HOME)/.asdf/installs/stylua/$(STYLUA_VERSION)/bin/stylua

# Check formatting.
.PHONY: testmft
testfmt: $(STYLUA)
	stylua --check lua/ scripts/ tests/

# Check docs are up to date.
.PHONY: testdocs
testdocs: deps/lua/doc.lua
	git checkout $(HELP_FILE)
	@$(CMD_MINI_DOC_GENERATE)
	git diff --exit-code $(HELP_FILE)

# Run mini.test tests.
.PHONY: test
test: deps/lua/test.lua deps/lua/nvim-treesitter/init.lua
	$(CMD_NVIM) -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

# Run CI tests.
.PHONY: testci
testci: testfmt testdocs test

# Format.
.PHONY: fmt
fmt: $(STYLUA)
	stylua lua/ scripts/ tests/

# Update docs.
.PHONY: docs
docs: deps/lua/doc.lua
	$(CMD_MINI_DOC_GENERATE)

deps/lua/test.lua:
	@mkdir -p deps/lua
	curl $(ECHASNOVSKI_GH_BASE_URL)/mini.test/$(MINI_TEST_GIT_HASH)/lua/mini/test.lua -o $@

deps/lua/doc.lua:
	@mkdir -p deps/lua
	curl $(ECHASNOVSKI_GH_BASE_URL)/mini.doc/$(MINI_DOC_GIT_HASH)/lua/mini/doc.lua -o $@

deps/lua/nvim-treesitter/init.lua:
	@mkdir -p deps/lua
	curl -L $(NVIM_TREESITTER_GH_BASE_URL)/archive/$(NVIM_TREESITTER_GIT_HASH).tar.gz \
	-o deps/nvim-treesitter.tar.gz
	cd deps && tar -xzf nvim-treesitter.tar.gz
	cp -r deps/nvim-treesitter-$(NVIM_TREESITTER_GIT_HASH)/lua/nvim-treesitter deps/lua/
	rm -rf deps/nvim-treesitter.tar.gz deps/nvim-treesitter-$(NVIM_TREESITTER_GIT_HASH)

$(STYLUA):
	asdf plugin add stylua
	asdf install stylua
