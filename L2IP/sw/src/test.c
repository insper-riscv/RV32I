#define LED_ADDR ((volatile unsigned int *)0x00001000)

void delay(int valor){
  for (int i = 0; i < valor; i++) { __asm__ volatile ("nop"); }
}

int main(void) {

    int vec[] = {1000, 100000, 100000};
    int i = 0;
    while (1) {
        
      //  if(i > 2)
      //      i = 0;
        
      //  *LED_ADDR = 0xFF;
      //   delay(vec[i]*15);
      // *LED_ADDR = 0x00;
       
      delay(vec[i]*vec[i+1]);
      //delay(vec[i]/vec[i+1]);

      //  *LED_ADDR = 0xFF;
      // delay(vec[i]*15);
      //    *LED_ADDR = 0x00;
      //  delay(vec[i]);
        
       i++;
    }
    return 0;
}
