library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library WORK;

--! Funções auxiliares de lógica abstrata, genérica para todos os casos.
package GENERICS is

    --! Para facilitar a criação de um banco de registradores, foi criado um tipo de variável que seria uma matriz de vetores.
    type t_std_logic_array is array(natural range <>) of std_logic_vector;

     --! Recebe um vetor arbitrário e retorna o mesmo invertendo a ordem os bits. Ou seja, para um dado vetor de tamanho `n downto 0`, seja `vector(n)` passa a ser `vector(0)`.
    function reverse_vector (l: in std_logic_vector) return std_logic_vector;

    --! Aplica lógica OU bit-a-bit em um vetor de tamanho n em estrutura de árvore de derivação. Esta abordagem torna os diagramas RTL mais compactos em comparação a abordagem encadeada da biblioteca padrão IEEE.
    --!
    --! Por exemplo, um vetor `v(3 downto 0)` reduzido em lógica encadeada resultaria num circuito equivalente:
    --! ```vhdl
    --! ( ( v(0) OR v(1) ) OR v(2) ) OR v(3)
    --! ```
    --! O mesmo vetor reduzido em lógica em àrvore reduz a profundidade do curcuito em `O(log n)` e facilita a vizualização de diagramas RTL:
    --! ```vhdl
    --! ( v(0) OR v(1) ) OR ( v(2) OR v(3) )
    --! ```
    function reduce_or  (l : std_logic_vector) return std_logic;

    --! Aplica lógica E bit-a-bit em um vetor de tamanho `N` em estrutura de árvore de derivação. Esta abordagem torna os diagramas RTL mais compactos em comparação a abordagem encadeada da biblioteca padrão IEEE.
    function reduce_and (l : std_logic_vector) return std_logic;

    --! Função que compara um vetor de dados dinâmico com um vetor de estático. O propósito é reduzir o vetor em lógica booleana E bit-a-bit incluindo negações conforme o vetor estático. O retorno é um único bit que assume valor lógico alto quando o vetor a ser comparado é igual ao vetor estático.
    --!
    --! Este é uma especificação do is_equal_dynamic para o caso em que um dos vetores define um valor constante. Isto gera um circuito com uso de menos recursos.
    function is_equal (l : std_logic_vector; r : std_logic_vector) return std_logic;

    --! Função que compara dois vetored dinâmicos. O propósito é reduzir o vetor XOR de ambos em lógica booleana E bit-a-bit. O retorno é um único bit que assume valor lógico alto quando ambos os vetores forem ignais.
    function is_equal_dynamic (l : std_logic_vector; r : std_logic_vector) return std_logic;

end package;

package body GENERICS is

    function reverse_vector (l: in std_logic_vector) return std_logic_vector is
        variable result : std_logic_vector(l'range);
        alias auxiliar  : std_logic_vector(l'reverse_range) is l;
    begin
        for i in auxiliar'range loop
            result(i) := auxiliar(i);
        end loop;
        return result;
    end function;

    function reduce_or (l : std_logic_vector) return std_logic is
        constant mid : integer := (l'high + l'low) / 2;
    begin
        if l'length = 1 then
            return l(l'low);
        elsif l'length = 2 then
            return l(l'low) OR l(l'high);
        elsif l'ascending then
            return reduce_or(l((mid + 1) to l'high)) OR reduce_or(l(l'low to mid));
        else
            return reduce_or(l(l'high downto (mid + 1))) OR reduce_or(l(mid downto l'low));
        end if;
    end function;

    function reduce_and (l : std_logic_vector) return std_logic is
        constant mid : integer := (l'high + l'low) / 2;
    begin
        if l'length = 1 then
            return l(l'low);
        elsif l'length = 2 then
            return l(l'low) AND l(l'high);
        elsif l'ascending then
            return reduce_and(l((mid + 1) to l'high)) AND reduce_and(l(l'low to mid));
        else
            return reduce_and(l(l'high downto (mid + 1))) AND reduce_and(l(mid downto l'low));
        end if;
    end function;

    function is_equal (l : std_logic_vector; r : std_logic_vector) return std_logic is
        variable base : std_logic_vector(r'range) := r;
        variable result : std_logic_vector(r'range);
    begin
        if r'ascending then
            base := reverse_vector(r);
        end if;

        for i in l'reverse_range loop
            if base(base'low + l'left - i) = '1' then
                result(i) := l(i);
            else
                result(i) := NOT(l(i));
            end if;
        end loop;

        return reduce_and(result);
    end function;

    function is_equal_dynamic (l : std_logic_vector; r : std_logic_vector) return std_logic is
    begin
        return reduce_and(l XNOR r);
    end function;

end package body;
