# Сборка C-версии исполняемых программ фильтра Калмана через CertiRocq.
# Каталог не участвует в dune и CI; сборка только вручную (см. README.md).

# Переключатель opam с CertiRocq. Пустое значение означает активный
# переключатель. Задайте SWITCH=<имя или путь>, если CertiRocq стоит в другом.
SWITCH ?=
OPAM   := opam exec $(if $(SWITCH),--switch $(SWITCH)) --
ROOT   := $(abspath ../..)
# Общие модули печати живут в extraction/common и собираются dune в отдельном
# каталоге сборки, чтобы не оставлять .vo рядом с исходниками.
COMMON := $(abspath ../../_build_certirocq/default/extraction/common)
SHOWQ  := -Q $(COMMON) KalmanShow

RUNTIME := $(shell $(OPAM) rocq c -where)/user-contrib/CertiRocq/Plugin/runtime
CC      := clang
CFLAGS  := -Wno-everything -O2 -fomit-frame-pointer -I$(RUNTIME) -Igenerated
RTOBJS  := $(RUNTIME)/gc_stack.o $(RUNTIME)/rocq_c_ffi.o \
           $(RUNTIME)/prim_int63.o $(RUNTIME)/prim_floats.o

.PHONY: smoke common-vo theories-vo kalman check clean

smoke: common-vo
	mkdir -p generated
	$(OPAM) rocq c -w -all $(SHOWQ) -Q . KalmanC smoke.v
	$(CC) $(CFLAGS) -c generated/smoke.c -o generated/smoke.o
	$(CC) $(CFLAGS) -c generated/smoke_bq.c -o generated/smoke_bq.o
	$(CC) $(CFLAGS) -c generated/glue_smoke.c -o generated/glue_smoke.o
	$(CC) $(CFLAGS) -o generated/smoke_bin main.c \
	    generated/smoke.o generated/glue_smoke.o $(RTOBJS) -lm
	$(CC) $(CFLAGS) -o generated/smoke_bq_bin main.c \
	    generated/smoke_bq.o generated/glue_smoke.o $(RTOBJS) -lm
	./generated/smoke_bin; echo
	./generated/smoke_bq_bin; echo

common-vo:
	cd $(ROOT) && $(OPAM) dune build --build-dir _build_certirocq \
	    extraction/common/figures.vo

theories-vo:
	cd $(ROOT) && $(OPAM) dune build --build-dir _build_certirocq \
	    theories/seqmx/inst_Q.vo

kalman: common-vo theories-vo
	mkdir -p generated
	$(OPAM) rocq c -w -all \
	    -Q $(ROOT)/_build_certirocq/default/theories Kalman \
	    $(SHOWQ) -Q . KalmanC kalman_c.v
	$(CC) $(CFLAGS) -c generated/kalman_c.c -o generated/kalman_c.o
	$(CC) $(CFLAGS) -c generated/glue_kalman.c -o generated/glue_kalman.o
	$(CC) $(CFLAGS) -o generated/kalman_c_bin main.c \
	    generated/kalman_c.o generated/glue_kalman.o $(RTOBJS) -lm

check:
	./generated/kalman_c_bin > generated/kalman_c.out
	python3 check.py generated/kalman_c.out $(ROOT)/paper/data

clean:
	rm -rf generated *.vo *.vok *.vos *.glob *.aux
