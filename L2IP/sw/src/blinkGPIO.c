#define GPIO_DIR_PTR      ((volatile unsigned int *)0xA0000000u) // DIR  (addr[5:2]=0000)
#define GPIO_OUT_SET_PTR  ((volatile unsigned int *)0xA0000008u) // SET  (addr[5:2]=0010)
#define GPIO_OUT_CLR_PTR  ((volatile unsigned int *)0xA000000Cu) // CLR  (addr[5:2]=0011)
#define GPIO_PINS_PTR     ((volatile unsigned int *)0xA0000024u) // PINS (addr[5:2]=1001)

#define LED_ADDR          ((volatile unsigned int *)0x90000000u) // LEDs on-board (8 bits)

static inline void nops(int n){
    for (volatile int i = 0; i < n; i++) {
        __asm__ volatile ("nop");
    }
}

int main(void){
    const unsigned D0 = 1u << 0;   // GPIO pin 0

    // Configura pino 0 como saída
    *GPIO_DIR_PTR = D0;
    nops(1000);   // só um respiro depois da configuração

    for(;;){
        unsigned pins;

        // --- Liga GPIO0 ---
        *GPIO_OUT_SET_PTR = D0;

        // Lê estado sincronizado do pino e espelha no LED0
        pins = *GPIO_PINS_PTR;
        *LED_ADDR = (pins & D0) ? 0x01u : 0x00u;

        nops(50000000);   // ~1s em 50 MHz (ajusta se quiser)

        // --- Desliga GPIO0 ---
        *GPIO_OUT_CLR_PTR = D0;

        // Lê de novo e espelha no LED0
        pins = *GPIO_PINS_PTR;
        *LED_ADDR = (pins & D0) ? 0x01u : 0x00u;

        nops(50000000);
    }

    return 0;
}

