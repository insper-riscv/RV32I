#define LED_ADDR ((volatile unsigned int *)0x00001000)

void delay(int valor){
    for (int i = 0; i < valor; i++) { __asm__ volatile ("nop"); }
}

int main(void) {
    while (1) {
        *LED_ADDR = 0xFF;
        delay(1000000);
        *LED_ADDR = 0x00;
        delay(1000000);
    }
    return 0;
}






         