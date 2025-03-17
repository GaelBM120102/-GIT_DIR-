#include<stdio.h>
 int main(){
  const float iva=0.16;
  const float precio=9256;
  int l;
  float at,ar,metros,imp,costoi,costof;
  printf("Cual es el valor de L: ");scanf("%d", & l);

  ar=l*(l/2.0);
  at=((l/3.0)*l)/2.0;
  metros=ar+at;
  costoi=metros*precio;
  imp=costoi*iva;
  costof=costoi+imp;

  printf("%f Metros\n", metros);
  printf("Costo Inicial: $%.2f", costoi);
  printf("\nIVA(16%): $%.2f", imp);
  printf("\nCosto Final: $%.2f", costof);

  return 0;
}
