#define LED_ADDR ((volatile unsigned short *)0x00001000)

int main(void) {
    volatile unsigned int i;
    unsigned int pattern = 1; 

    for (;;) {
        *LED_ADDR = (unsigned short)pattern;
        for (i = 0; i < 1250000; i++) { __asm__ volatile ("nop"); }
        pattern <<= 1;
        if (pattern == 256u) pattern = 1u;
        *LED_ADDR = (unsigned short)pattern;
        for (i = 0; i < 1250000; i++) { __asm__ volatile ("nop"); }
    }

    return 0;
}
