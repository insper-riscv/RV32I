#define LED_ADDR ((volatile unsigned int *)0x00001000)

int main(void) {
    volatile unsigned int i;
    while (1) {
        *LED_ADDR = 0xFF;
        for (i = 0; i < 1250000; i++) { __asm__ volatile ("nop"); }
        *LED_ADDR = 0x00;
        for (i = 0; i < 1250000; i++) { __asm__ volatile ("nop"); }
    }
    return 0;
}
