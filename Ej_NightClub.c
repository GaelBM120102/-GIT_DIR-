#include<stdio.h>
int main(){
  const int cover=500;
  int numH, numM;
  const float desc=0.25;
  float total;

  printf("Ingresa numero de Mujeres: "); scanf("%d",& numM);
  printf("\nIngresa numero de Hombres: "); scanf("%d",& numH);

  total=(numH*cover)+(numM*cover)-(numM*cover*desc);

  printf("\nEl Total es de: $%.2f", total);

  return 0;
}
