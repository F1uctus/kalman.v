# Building the C version of the Kalman filter executable programs through CertiRocq.
# The directory is not part of dune or CI; it is built manually (see README.md).

# The opam switch with CertiRocq. An empty value means the active switch. Set
# SWITCH=<name or path> if CertiRocq lives in another one.
SWITCH ?=
OPAM   := opam exec $(if $(SWITCH),--switch $(SWITCH)) --
ROOT   := $(abspath ../..)
# The shared printing modules live in extraction/common and are built by dune in
# a separate build directory, so as not to leave .vo next to the sources.
COMMON := $(abspath ../../_build_certirocq/default/extraction/common)
SHOWQ  := -Q $(COMMON) KalmanShow
OUT    := generated

# The coefficient ring of the instantiation: Q gives verified numeric values,
# F64 gives unverified values over double precision numbers. Both sides are
# compiled by one pipeline; the instantiation module and the driver differ.
NUMERICS ?= Q
ifeq ($(NUMERICS),F64)
  INST    := inst_Float64
  FIGURES := figures_F64
  DRIVER  := kalman_c_F64
else
  INST    := inst_Q
  FIGURES := figures_Q
  DRIVER  := kalman_c_Q
endif

RUNTIME := $(shell $(OPAM) rocq c -where)/user-contrib/CertiRocq/Plugin/runtime
CC      := clang
CFLAGS  := -Wno-everything -O2 -fomit-frame-pointer -I$(RUNTIME) -I$(OUT)
RTOBJS  := $(RUNTIME)/gc_stack.o $(RUNTIME)/rocq_c_ffi.o \
           $(RUNTIME)/prim_int63.o $(RUNTIME)/prim_floats.o

EXPERIMENTS := dare gramian schur run run3 orthogonality lyapunov spectral
dare_JSON         := dare_convergence.json
gramian_JSON      := gramian.json
schur_JSON        := schur_stability.json
run_JSON          := kalman_run.json
run3_JSON         := kalman_run_3d.json
orthogonality_JSON:= orthogonality.json
lyapunov_JSON     := lyapunov.json
spectral_JSON     := spectral.json

.PHONY: all smoke vo compile clean $(EXPERIMENTS)

all: $(EXPERIMENTS)

smoke: vo
	mkdir -p $(OUT)
	$(OPAM) rocq c -w -all $(SHOWQ) -Q . KalmanC smoke.v
	$(CC) $(CFLAGS) -c $(OUT)/smoke.c -o $(OUT)/smoke.o
	$(CC) $(CFLAGS) -c $(OUT)/smoke_bq.c -o $(OUT)/smoke_bq.o
	$(CC) $(CFLAGS) -c $(OUT)/glue_smoke.c -o $(OUT)/glue_smoke.o
	$(CC) $(CFLAGS) -o $(OUT)/smoke_bin main.c \
	    $(OUT)/smoke.o $(OUT)/glue_smoke.o $(RTOBJS) -lm
	$(CC) $(CFLAGS) -o $(OUT)/smoke_bq_bin main.c \
	    $(OUT)/smoke_bq.o $(OUT)/glue_smoke.o $(RTOBJS) -lm
	./$(OUT)/smoke_bin; echo
	./$(OUT)/smoke_bq_bin; echo

vo:
	cd $(ROOT) && $(OPAM) dune build --build-dir _build_certirocq \
	    theories/seqmx/$(INST).vo extraction/common/$(FIGURES).vo

compile: vo
	mkdir -p $(OUT)
	$(OPAM) rocq c -w -all \
	    -Q $(ROOT)/_build_certirocq/default/theories Kalman \
	    $(SHOWQ) -Q . KalmanC $(DRIVER).v

define RUN_ONE
$(1): compile
	$(CC) $(CFLAGS) -o $(OUT)/$(1)_bin main.c \
	    $(OUT)/$(1).c $(OUT)/glue_$(1).c $(RTOBJS) -lm
	./$(OUT)/$(1)_bin > $(OUT)/$($(1)_JSON)
endef
$(foreach e,$(EXPERIMENTS),$(eval $(call RUN_ONE,$(e))))

clean:
	rm -rf $(OUT) *.vo *.vok *.vos *.glob *.aux
