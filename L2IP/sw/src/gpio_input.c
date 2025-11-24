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
    /* máscaras para os 4 pinos do motor e para o botão */
    const unsigned D0 = (1u << 0);
    const unsigned D1 = (1u << 1);
    const unsigned D2 = (1u << 2);
    const unsigned D3 = (1u << 3);
    const unsigned BTN = (1u << 4);     // botão em GPIO4

    const unsigned ALL4 = D0 | D1 | D2 | D3;

    /* configura os 4 pinos do motor como saída, o pino 4 (botão) como entrada */
    *GPIO_DIR_PTR = ALL4;   // só as saídas; bit 4 fica 0 (entrada)
    delay(1000); /* respiro */

    /* sequência de passos (one-phase) */
    const unsigned step_seq[4] = { D0, D1, D2, D3 };
    unsigned prev = 0;
    unsigned idx = 0;

    for (;;) {
        unsigned next = step_seq[idx];

        /* lê o estado atual dos pinos */
        unsigned pins = *GPIO_PINS_PTR;

        if (pins & BTN) {
            /* --- botão pressionado: gira motor --- */

            *GPIO_OUT_CLR_PTR = prev & ALL4;  // limpa fase anterior
            *GPIO_OUT_SET_PTR = next & ALL4;  // ativa próxima fase

            *LED_ADDR = (next & ALL4);        // espelha nos LEDs

            prev = next;
            idx = (idx + 1) & 3;              // próximo passo

            delay(20000);
        } else {
            /* --- botão solto: motor parado, LEDs apagados --- */
            *GPIO_OUT_CLR_PTR = ALL4;         // garante motor desligado
            *LED_ADDR = 0x00;
        }
    }

    return 0;
}
