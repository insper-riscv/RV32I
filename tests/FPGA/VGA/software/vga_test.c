// vga_test.c — desenha um tabuleiro simples no VGA (modo caractere)

#define VGA_BASE     0x80000000u
#define VGA_POSCOL   (*(volatile unsigned int*)(VGA_BASE + 0x00))
#define VGA_POSLIN   (*(volatile unsigned int*)(VGA_BASE + 0x04))
#define VGA_DADOIN   (*(volatile unsigned int*)(VGA_BASE + 0x08))
#define VGA_WE       (*(volatile unsigned int*)(VGA_BASE + 0x0C))

// Cores (2 bits nos MSBs de dadoIN)
#define COLOR_RED     0u
#define COLOR_BLUE    1u
#define COLOR_GREEN   2u
#define COLOR_WHITE   3u

// Layout do driver padrão:
// charPerLine = 20 -> 20 colunas
// charRAMAddrWidth = 9 -> 512 tiles -> ~25 linhas (20*25=500)
#define COLS 20u
#define LINS 25u

static inline void vga_put_tile(unsigned col, unsigned lin, unsigned color2b, unsigned char_idx6b) {
    // Define pos e dado, e dá um pulso de escrita (1 store em VGA_WE)
    VGA_POSCOL = col & 0xFFu;
    VGA_POSLIN = lin & 0xFFu;
    VGA_DADOIN = ((color2b & 3u) << 6) | (char_idx6b & 0x3Fu);
    VGA_WE     = 1u;  // hardware já faz o pulso de 1 ciclo
}

static void clear_screen(unsigned char_idx) {
    for (unsigned y = 0; y < LINS; ++y)
        for (unsigned x = 0; x < COLS; ++x)
            vga_put_tile(x, y, COLOR_GREEN, char_idx); // fundo verdinho só pra diferenciar
}

int main(void) {
    // Limpa a “tela” com um char base (0)
    clear_screen(0);

    // Desenha um tabuleiro (xadrez) usando char 1 e 2 alternados em branco
    for (unsigned y = 0; y < LINS; ++y) {
        for (unsigned x = 0; x < COLS; ++x) {
            unsigned char_idx = ((x ^ y) & 1u) ? 1u : 2u;  // alterna 1/2
            vga_put_tile(x, y, COLOR_WHITE, char_idx);
        }
    }

    // Mantém vivo
    for (;;) { /* loop infinito */ }
}
