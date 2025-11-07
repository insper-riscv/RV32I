#define LED_ADDR ((volatile unsigned short *)0x00004000)

void delay(int value){
    for (int i = 0; i < value; i++) { __asm__ volatile ("nop"); }
}

int main(void) {
    unsigned int pattern = 1; 
    while(1) {
        *LED_ADDR = (unsigned short)pattern;
        delay(1250000);
        pattern <<= 1;
        if (pattern == 256u) pattern = 1u;
        *LED_ADDR = (unsigned short)pattern;
        delay(1250000);
    }

    return 0;
}
