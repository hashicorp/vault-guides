/*
 * Copyright IBM Corp. 2017, 2026
 */

#if defined(OPENSSL_NO_ASM)
# include "./dso_conf_no-asm.h"
#else
# include "./dso_conf_asm.h"
#endif
