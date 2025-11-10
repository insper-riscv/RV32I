#define LED_ADDR ((volatile unsigned int *)0x00004000)

const unsigned int pattern[8] = {1, 2, 4, 8, 16, 32, 64, 128}; // .rodata

void delay(int n) {
    for (volatile int i = 0; i < n; i++) __asm__ volatile("nop");
}

int main(void) {
    while (1) {
        for (int i = 0; i < 8; i++) {
            *LED_ADDR = pattern[i];
            delay(300000);
        }
    }
}
