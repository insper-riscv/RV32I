#define LED_ADDR ((volatile unsigned int *)0x00004000)

int led_value = 0xAA;  // variável global inicializada (.data)

void delay(int n) {
    for (volatile int i = 0; i < n; i++) __asm__ volatile("nop");
}

int main(void) {
    while (1) {
        *LED_ADDR = led_value;  // deve acender LEDs conforme 0xAA
        delay(500000);
        *LED_ADDR = ~led_value; // inverso
        delay(500000);
    }
}
