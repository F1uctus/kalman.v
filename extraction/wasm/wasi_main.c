/* Драйвер WASI: вызывает скомпилированную CertiRocq программу body и
 * печатает возвращённый список байтов в стандартный вывод. Список
 * обходится функциями сгенерированной склейки. */
#include <stdio.h>
#include "gc_stack.h"

extern value body(struct thread_info *);
extern value *get_args(value);
extern unsigned long long get_unboxed_ordinal(value);
extern unsigned long long get_Corelib_Init_Datatypes_list_tag(value);

int main(void) {
  struct thread_info *tinfo = make_tinfo();
  value v = body(tinfo);
  while (get_Corelib_Init_Datatypes_list_tag(v) == 1) { /* cons */
    value *args = get_args(v);
    putchar((int)get_unboxed_ordinal(args[0]));
    v = args[1];
  }
  return 0;
}
