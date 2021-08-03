#ifndef COMMON_H
#define COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "stdint.h"

typedef struct {
    union {
        int i_val;
        float f_val;
        char* s_val;
    } varval;
    char* id;
    char* type;   
    char* op;
    int8_t addr;
    int8_t is_arr;
} val_info; 

#endif /* COMMON_H */