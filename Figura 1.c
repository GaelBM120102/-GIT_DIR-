#include<math.h>
#include<stdio.h>
 int main(){
  int a=3, b=4;
  float at=(b*a/2);
  float pt=(a+b)+sqrt(pow(a,2)+pow(b,2));

  printf("El area total es: %.2f", at);
  printf("\nEl perimetro total es: %.2f", pt);


  return 0;
}
