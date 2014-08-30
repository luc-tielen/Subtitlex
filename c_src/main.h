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

/*
 * Extracts and returns the name of the episode out of the incoming databuffer.
 */
char* get_episode_name(byte buffer[], int length);

/*
 * Returns hash = filesize + checksum first 64Kb + checksum last 64Kb.
 */
uint64_t compute_hash(FILE* file);

/*
 * Sends the hash back to Elixir.
 */
void send_hash(uint64_t hash);

#endif
