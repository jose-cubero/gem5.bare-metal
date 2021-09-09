unsigned int getCPUID(void);

// Functions returning final value of SCTLR 
unsigned int enable_caches(void);
unsigned int disable_caches(void);

void cleanInvalidateDCache(void);

void _exit(int);
