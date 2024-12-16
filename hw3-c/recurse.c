#include <stdio.h>
#include <stdlib.h>

int recurseFunction(int v) { 

  if (v == 0){
    return 2;
  }
  return 2 * (v+1) + 3 * (recurseFunction(v-1)) - 17;
}

int main(int argc, char* argv[]) {
  int seq = atoi(argv[1]); // // initializes an int that initally stores a 0; this is N in Sn = 3^n - 3
  int final = recurseFunction(seq); // use helper method
  printf("%d\n", final); // reminder to self that adding a \n ensures that the otuput goes to a new line after printing the number

  return EXIT_SUCCESS;
}
