#include <stdio.h>
#include <stdlib.h>

int powerThree(int v) { // helper method that takes in an exponent of v, and finds 3^v - 3

  int multiplication = 1; 
  if (v == 0){
    return multiplication - 3;
  }

  for(int i = 0; i < v; i++){ // multiples multiplication by 3 v times
    multiplication *= 3;
  }

  return multiplication - 3; // subtract 3 at the end
}

int main(int argc, char* argv[]) {
  int seq = atoi(argv[1]); // // initializes an int that initally stores a 0; this is N in Sn = 3^n - 3
  int final = powerThree(seq); // use helper method
  printf("%d\n", final); // reminder to self that adding a \n ensures that the otuput goes to a new line after printing the number

  return EXIT_SUCCESS;
}
