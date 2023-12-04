/*
 * Copyright (c) HashiCorp, Inc.
 * SPDX-License-Identifier: MPL-2.0
 */

#if defined(OPENSSL_NO_ASM)
# include "./bn_conf_no-asm.h"
#else
# include "./bn_conf_asm.h"
#endif
