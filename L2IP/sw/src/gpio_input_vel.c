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

    /* níveis de velocidade: índice 0 => nível 1 (mais lento), índice 4 => nível 5 (mais rápido) */
    const unsigned delays[5] = {
        200000u, /* nível 1 - mais lento */
        80000u, /* nível 2 */
        40000u,  /* nível 3 */
        20000u,  /* nível 4 */
        10000u    /* nível 5 - mais rápido */
    };

    unsigned level = 1; /* inicia em nível 1 */
    unsigned prev_btn_state = 0;

    for (;;) {
        unsigned next = step_seq[idx];

        /* lê o estado atual dos pinos (inclui botão) */
        unsigned pins = *GPIO_PINS_PTR;
        unsigned btn = (pins & BTN) ? 1u : 0u;

        /* detecta borda de subida do botão (pressionamento) */
        if (btn && !prev_btn_state) {
            /* debounce simples: espera um curto intervalo e confirma */
            delay(20000);
            if ((*GPIO_PINS_PTR & BTN) != 0) {
                /* incrementa nível e dá wrap de 1..5 */
                level++;
                if (level > 5) level = 1;

                /* espera até soltar o botão para evitar múltiplos incrementos */
                while ((*GPIO_PINS_PTR & BTN) != 0) {
                    /* pequeno nop para não queimar o bus */
                    __asm__ volatile ("nop");
                }
            }
        }
        prev_btn_state = btn;

        /* --- realiza passo do motor --- */
        *GPIO_OUT_CLR_PTR = prev & ALL4;  // limpa fase anterior
        *GPIO_OUT_SET_PTR = next & ALL4;  // ativa próxima fase

        /* monta valor para LEDs:
           - bits [2:0] ou [3:0] mostram fase (0..3)
           - bits [6:4] mostram nível atual (binário) para feedback visual
           exemplo: LEDs[3:0] = phase, LEDs[6:4] = level */
        unsigned led_phase = (next & ALL4);         /* LEDs 0..3 */
        unsigned led_level = (level & 0x7) << 4;    /* LED bits 4..6 */
        *LED_ADDR = (led_phase & 0x0F) | (led_level & 0x70);

        prev = next;
        idx = (idx + 1) & 3; /* próximo passo 0..3 */

        /* espera de acordo com o nível atual (quanto maior o nível, menor o delay) */
        delay(delays[level - 1]);
    }

    return 0;
}
