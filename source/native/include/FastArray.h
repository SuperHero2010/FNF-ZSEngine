#ifndef FAST_ARRAY_H
#define FAST_ARRAY_H

#include <hx/CFFI.h>

#ifdef __cplusplus
extern "C" {
#endif

void fast_array_concat_push(value arr, value items);

#ifdef __cplusplus
}
#endif

#endif