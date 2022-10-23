#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char **argv)
{
    if(argc <= 2)
    {
        printf("Not enough arguments are given\n");
        exit(1);
    }
    int tr = trace(atoi(argv[1]));
    if (tr < 0)
    {
        printf("Error in tracing\n");
        exit(1);
    }   
    exec(argv[2], &argv[2]);
    exit(1);
}