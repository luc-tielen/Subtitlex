#include "main.h"
#include <string.h>

/*
 * Extracts the name of the episode out of the incoming databuffer.
 */
char* get_episode_name(byte buffer[], int length)
{
    char *str;

    if((str = (char *)malloc(length * sizeof(char))) == NULL)
    {
        return NULL;
    }
    
    memcpy(str, buffer, length);
    return str;
}

/*
 * Hash = filesize + checksum first 64Kb + checksum last 64Kb.
 */
uint64_t compute_hash(FILE *handle)
{
    uint64_t hash, file_size, tmp, i;
    
    //Calculate file_size:
    fseek(handle, 0, SEEK_END);
    file_size = ftell(handle);
    hash = file_size;
    
    //Calculate checksums:
    fseek(handle, 0, SEEK_SET);
    for(tmp = 0, i = 0; 
        i < 65536 / sizeof(tmp) && fread((char*)&tmp, sizeof(tmp), 1, handle); 
        hash += tmp, i++);

    fseek(handle, (long)MAX(0, file_size - 65536), SEEK_SET);
    for(tmp = 0, i = 0;
        i < 65536 / sizeof(tmp) && fread((char*)&tmp, sizeof(tmp), 1, handle);
        hash += tmp, i++);

    return hash;
}

/*
 * Sends an error message back to Elixir.
 * (error_msg has to be terminated with a \0 character for this function to
 *  work properly).
 */
void send_error(char *error_msg)
{
    send_msg(error_msg, strlen(error_msg));
}

/*
 * Sends the hash back to Elixir.
 */
void send_hash(uint64_t hash)
{
    byte buffer[8];
    int i;

    for(i = 0; i < 8; i++)
    {
        buffer[i] = (hash >> ((7 - i) * 8)) & 0xff;
    }
/*
    buffer[0] = (hash >> 56) & 0xff;
    buffer[1] = (hash >> 48) & 0xff;
    buffer[2] = (hash >> 40) & 0xff;
    buffer[3] = (hash >> 32) & 0xff;
    buffer[4] = (hash >> 24) & 0xff;
    buffer[5] = (hash >> 16) & 0xff;
    buffer[6] = (hash >> 8) & 0xff;
    buffer[7] = hash & 0xff;*/
    send_msg(buffer, 8);
}

int main(void)
{
    int bytes_read;
    byte buffer[MAX_BUFFER_SIZE];
    
    char *episode_name;
    FILE *file;
    uint64_t hash;

    while((bytes_read = read_msg(buffer)) > 0)
    {
        episode_name = get_episode_name(buffer, bytes_read);
        if(episode_name == NULL)
        {
            send_error("Error reading incoming data.");
            return 1; // or continue; ?
        }

        file = fopen(episode_name, "rb");
        if(file == NULL)
        {
            send_error("Error opening file.");
            return 1; // or continue; ?
        }
        
        hash = compute_hash(file);
        send_hash(hash);
        fclose(file);
        free(episode_name);
    }

    return 0;
}
