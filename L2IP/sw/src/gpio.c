#include <stdint.h>

/* endereços (conforme teu mapa) */
#define GPIO_DIR_PTR      ((volatile unsigned int *)0xA0000000u) // DIR  (addr[5:2]=0000)
#define GPIO_OUT_SET_PTR  ((volatile unsigned int *)0xA0000008u) // SET  (addr[5:2]=0010)
#define GPIO_OUT_CLR_PTR  ((volatile unsigned int *)0xA000000Cu) // CLR  (addr[5:2]=0011)
#define GPIO_PINS_PTR     ((volatile unsigned int *)0xA0000024u) // PINS (addr[5:2]=1001)

#define LED_ADDR          ((volatile unsigned int *)0x90000000u) // LEDs on-board (8 bits)

static inline void delay(volatile int n){
    for (volatile int i = 0; i < n; i++) {
        __asm__ volatile ("nop");
    }
}

int main(void){
    /* máscaras para os 4 pinos/leds que queremos usar */
    const unsigned D0 = (1u << 0);
    const unsigned D1 = (1u << 1);
    const unsigned D2 = (1u << 2);
    const unsigned D3 = (1u << 3);

    /* conjunto de 4 bits */
    const unsigned ALL4 = D0 | D1 | D2 | D3;

    /* configura os 4 pinos como saída */
    *GPIO_DIR_PTR = ALL4;
    delay(1000); /* respiro */

    /* sequência de passos (one-phase) */
    const unsigned step_seq[4] = { D0, D1, D2, D3 };
    unsigned prev = 0;
    unsigned idx = 0;

    for (;;) {
        unsigned next = step_seq[idx];

        /* limpa os bits previamente ativos (apenas os das 4 linhas do motor) */
        *GPIO_OUT_CLR_PTR = prev & ALL4;

        /* ativa os bits da próxima fase */
        *GPIO_OUT_SET_PTR = next & ALL4;

        /* escreve nos LEDs: espelha as 4 linhas nos leds 0..3 */
        *LED_ADDR = (next & ALL4); /* LED0..3 acendem conforme next */

        /* guarda como previous e avança sequência */
        prev = next;
        idx = (idx + 1) & 3; /* ciclo 0..3 */

        /* tempo entre passos (ajusta conforme velocidade desejada) */
        delay(20000);
    }

    return 0;
}
