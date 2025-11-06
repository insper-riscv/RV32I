#define GPIO_DIR_PTR      ((volatile unsigned int *)0x80000000u) // DIR (addr[5:2]=0000)
#define GPIO_OUT_SET_PTR  ((volatile unsigned int *)0x80000008u) // SET (addr[5:2]=0010)
#define GPIO_OUT_CLR_PTR  ((volatile unsigned int *)0x8000000Cu) // CLR (addr[5:2]=0011)
#define GPIO_PINS_PTR     ((volatile unsigned int *)0x80000024u) // PINS(addr[5:2]=1001)

#define LED_ADDR          ((volatile unsigned int *)0x90000000u) // LEDs on-board (8 bits)

static inline void nops(int n){ for (volatile int i=0;i<n;i++) __asm__ volatile("nop"); }

int main(void){
    const unsigned D0  = 1u << 0;   // saída
    const unsigned D10 = 1u << 10;  // entrada

    for(;;){
        // 1) Configura: D0 como saída, D10 permanece entrada (bit=0 por omissão)
        *GPIO_DIR_PTR = D0;
        nops(2);

        // 2) Liga D0 (~3,3 V)
        *GPIO_OUT_SET_PTR = D0;
        nops(2);

        // 3) Lê PINS e espelha D10 no LED0
        unsigned pins1 = *GPIO_PINS_PTR;
        *LED_ADDR = (pins1 & D10) ? 0x01 : 0x00;
        nops(2);

        // 4) Desliga D0 (0 V)
        *GPIO_OUT_CLR_PTR = D0;
        nops(2);

        // 5) Lê PINS e espelha D10 no LED0 de novo
        unsigned pins2 = *GPIO_PINS_PTR;
        *LED_ADDR = (pins2 & D10) ? 0x01 : 0x00;
        nops(2);
    }
    return 0;
}
