// Determines the address of an environment variable. Useful for determining the
// address of shell code during local exploits.
//
// Usage:
//  $ gcc -o ./global_warming_xxxx ./global_warming.c
//  $ ./global_warming_xxxx SHELL_CODE
//
// Note: that the name of the compiled binary (including the './') should be as
// long as the path used to invoke the target binary.

#include<stdlib.h>

int main(int argc, char** argv) {
    if (argc != 2) {
        printf("usage: global_warming ENV_VAR\n");
        return -1;
    }

    printf("%x\n", getenv(argv[1]));
}
