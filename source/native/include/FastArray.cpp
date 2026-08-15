#include <hx/CFFI.h>
#include <string.h>
#include <stdlib.h>

extern "C" {
    DEFINE_PRIM(void, fast_array_concat_push, 2)
    {
        value arr = val_arg1;
        value items = val_arg2;

        if (val_is_null(arr) || val_is_null(items)) return;

        int arrLen = val_array_size(arr);
        int itemsLen = val_array_size(items);
        if (itemsLen == 0) return;

        val_array_set_size(arr, arrLen + itemsLen);

        void* arrData = val_array_data(arr);
        void* itemsData = val_array_data(items);

        size_t itemSize = sizeof(value);
        size_t bytesToCopy = itemsLen * itemSize;
        memcpy((char*)arrData + (arrLen * itemSize), itemsData, bytesToCopy);
    }
}