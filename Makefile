HELP_FILE := ./doc/treescope.txt
NVIM_CMD := nvim --headless --noplugin
MINI_DOC_GENERATE_CMD := $(NVIM_CMD) -u ./scripts/minidoc_init.lua

# Neovim plugins versions.
# These are dev dependencies.
MINI_DOC_GIT_COMMIT := v0.17.0
MINI_TEST_GIT_COMMIT := v0.17.0
NVIM_TREESITTER_GIT_COMMIT := 2f5d4c3f3c675962242096bcc8e586d76dd72eb2

# Check formatting.
.PHONY: testfmt
testfmt:
	stylua --check lua/ scripts/ tests/

# Check docs are up to date.
.PHONY: testdocs
testdocs: deps/mini.doc
	STDOUT=true $(MINI_DOC_GENERATE_CMD) | diff $(HELP_FILE) -

# Run mini.test tests.
.PHONY: test
test: deps/mini.test deps/nvim-treesitter
	$(NVIM_CMD) -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

# Run CI tests.
.PHONY: ci
ci: testfmt testdocs test

# Format.
.PHONY: fmt
fmt:
	stylua lua/ scripts/ tests/

# Update docs.
.PHONY: docs
docs: deps/mini.doc
	$(MINI_DOC_GENERATE_CMD)

deps/mini.test:
	@mkdir -p deps
	git clone --depth 1 --branch $(MINI_TEST_GIT_COMMIT) \
	https://github.com/nvim-mini/mini.test \
	$@

deps/mini.doc:
	@mkdir -p deps
	git clone --depth 1 --branch $(MINI_DOC_GIT_COMMIT) \
	https://github.com/nvim-mini/mini.doc \
	$@

deps/nvim-treesitter:
	@mkdir -p deps
	git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter $@
	cd $@ && git fetch --depth 1 origin $(NVIM_TREESITTER_GIT_COMMIT) \
	&& git checkout $(NVIM_TREESITTER_GIT_COMMIT)
