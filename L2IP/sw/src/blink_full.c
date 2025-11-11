/* led_patterns.c
 * Exemplo mínimo: constantes (.rodata) + globals inicializados (.data)
 * Só usa LED_ADDR (periférico) — sem bibliotecas externas.
 */

#define LED_ADDR ((volatile unsigned int *)0x90000000u)
typedef unsigned int u32;

/* -------------------------
 * Constantes (ficam em .rodata)
 * ------------------------- */
const u32 pattern_basic[8] = {
    0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80
};

const u32 pattern_alternate[8] = {
    0x55, 0xAA, 0xFF, 0x00, 0xFF, 0xAA, 0x55, 0x00
};

/* -------------------------
 * Variáveis globais inicializadas (ficam em .data)
 * ------------------------- */
u32 mode = 0;         /* 0..3 : qual padrão executar */
u32 speed = 600000;   /* controla a duração do delay (maior = mais lento) */
u32 led_value = 0xAA; /* exemplo de valor em .data usado em alguns padrões */

/* -------------------------
 * Delay simples (busy-wait)
 * ------------------------- */
static void delay(volatile u32 n)
{
    while (n--) {
        __asm__ volatile("nop");
    }
}

/* -------------------------
 * Padrões implementados
 * -------------------------
 * mode 0 : "caminho" para a direita usando pattern_basic (um LED acende por vez)
 * mode 1 : "caminho" para a esquerda (reverse of mode 0)
 * mode 2 : alterna valores de pattern_alternate
 * mode 3 : escreve led_value (valor em .data) e seu inverso
 * ------------------------- */
int main(void)
{
    u32 i;

    for (;;) {
        if (mode == 0) {
            /* desloca para a direita (um LED aceso) */
            for (i = 0; i < 8; ++i) {
                *LED_ADDR = pattern_basic[i];
                delay(speed);
            }
        } else if (mode == 1) {
            /* desloca para a esquerda (reverse) */
            for (i = 0; i < 8; ++i) {
                *LED_ADDR = pattern_basic[7 - i];
                delay(speed);
            }
        } else if (mode == 2) {
            /* alterna sequência pré-definida constante (.rodata) */
            for (i = 0; i < 8; ++i) {
                *LED_ADDR = pattern_alternate[i];
                delay(speed);
            }
        } else {
            /* mode >= 3: usa variável global inicializada (.data) e seu complemento */
            *LED_ADDR = led_value;
            delay(speed);
            *LED_ADDR = ~led_value;
            delay(speed);
        }

        /* Para demonstrar variação: muda modo automaticamente (opcional) */
        /* comentar se quiser controlar mode externamente */
        mode = (mode + 1) & 3;  /* ciclo 0..3 */
    }

    return 0;
}
