#include<stdio.h>
#include<math.h>
 int main(){
   int l=7;
   float at=(3.0*((l*l)/2.0))+(l*l)+((2*l)*l);
   float h= sqrt(pow(l,2)+pow(l,2)), pt=(8*l)+(h*3);

   printf("El area es: %.2f\n", at);
   printf("El perimetro es: %.2f", pt);

   return 0;
 }
