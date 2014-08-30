#include "main.h"
#include <string.h>

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

void send_hash(uint64_t hash)
{
    byte buffer[8];
    int i;

    for(i = 0; i < 8; i++)
    {
        buffer[i] = (hash >> ((7 - i) * 8)) & 0xff;
    }

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
            return 1;
        }

        file = fopen(episode_name, "rb");
        if(file == NULL)
        {
            send_error("Error opening file.");
            return 1;
        }
        
        hash = compute_hash(file);
        send_hash(hash);

        fclose(file);
        free(episode_name);
    }

    return 0;
}
