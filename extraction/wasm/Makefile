# Сборка сырых данных фигур через backend C конвейера CertiRocq,
# скомпилированный в wasm32-wasi и исполняемый wasmtime. Каталог не в dune
# и не в CI; сборка только вручную (см. README.md). Прямой backend Wasm
# непригоден: он без сборки мусора и переполняет память на этих термах.

# Переключатель opam с CertiRocq. Пустое значение означает активный
# переключатель. Задайте SWITCH=<имя или путь>, если CertiRocq стоит в другом.
SWITCH  ?=
OPAM    := opam exec $(if $(SWITCH),--switch $(SWITCH)) --
ROOT    := $(abspath ../..)
# Общие модули печати живут в extraction/common.
SHOWQ   := -Q ../common KalmanShow
OUT     := generated
RT      := $(shell $(OPAM) rocq c -where)/user-contrib/CertiRocq/Plugin/runtime
SYSROOT ?= /usr/share/wasi-sysroot
CC      := clang
CFLAGS  := --target=wasm32-wasi --sysroot=$(SYSROOT) -O2 -Wno-everything -I$(RT) -I$(OUT) -I. -I../c
LDFLAGS := -Wl,-z,stack-size=268435456
WASMTIME?= wasmtime
WTFLAGS := run --wasm max-wasm-stack=209715200
RTSRC   := $(RT)/gc_stack.c $(RT)/rocq_c_ffi.c $(RT)/prim_int63.c $(RT)/prim_floats.c

EXPERIMENTS := dare gramian schur run run3 orthogonality lyapunov spectral
dare_JSON         := dare_convergence.json
gramian_JSON      := gramian.json
schur_JSON        := schur_stability.json
run_JSON          := kalman_run.json
run3_JSON         := kalman_run_3d.json
orthogonality_JSON:= orthogonality.json
lyapunov_JSON     := lyapunov.json
spectral_JSON     := spectral.json

.PHONY: all vo compile clean $(EXPERIMENTS)

all: $(EXPERIMENTS)

vo:
	cd $(ROOT) && $(OPAM) dune build --build-dir _build_certirocq \
	    theories/seqmx/inst_Q.vo theories/seqmx/gramian.vo theories/seqmx/closed_loop.vo
	$(OPAM) rocq c -w -all $(SHOWQ) ../common/show.v
	$(OPAM) rocq c -w -all $(SHOWQ) ../common/show_json.v
	$(OPAM) rocq c -w -all \
	    -Q $(ROOT)/_build_certirocq/default/theories Kalman \
	    $(SHOWQ) ../common/figures.v

compile: vo
	mkdir -p $(OUT)
	$(OPAM) rocq c -w -all \
	    -Q $(ROOT)/_build_certirocq/default/theories Kalman \
	    $(SHOWQ) -Q . KalmanWasm kalman_wasm.v

define RUN_ONE
$(1): compile
	$(CC) $(CFLAGS) -o $(OUT)/$(1).wasm wasi_main.c \
	    $(OUT)/$(1).c $(OUT)/glue_$(1).c $(RTSRC) $(LDFLAGS)
	$(WASMTIME) $(WTFLAGS) $(OUT)/$(1).wasm > $(OUT)/$($(1)_JSON)
endef
$(foreach e,$(EXPERIMENTS),$(eval $(call RUN_ONE,$(e))))

clean:
	rm -rf $(OUT) *.vo *.vok *.vos *.glob *.aux
	rm -f ../common/*.vo ../common/*.vok ../common/*.vos ../common/*.glob
