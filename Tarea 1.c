#include<stdio.h>
int main(){
  int x=3;
  float res=(((float)(1.0/2.0)*x)+((float)(3+x)/2.0)*(2.0*(x*x)))/((2.0+3.0)*x);
  printf("El resultado es: %.1f", res);



  return 0;
}
