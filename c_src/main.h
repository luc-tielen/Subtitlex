#ifndef MAIN_H
#define MAIN_H
#include <elixir_comm.h>

//Implementation from:
//http://trac.opensubtitles.org/projects/opensubtitles/wiki/HashSourceCodes

#include <stdio.h>
#include <stdlib.h>

#define MAX(x,y) ((x > y) ? (x) : (y))

#ifndef uint64_t
#define uint64_t unsigned long long
#endif

char* get_episode_name(byte buffer[], int length);
uint64_t compute_hash(FILE *file);
void send_error(char *error_msg);
void send_hash(uint64_t hash);

#endif
