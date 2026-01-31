#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#define SHM_SIZE 2048
void flip_case(char *str) {
for (int i = 0; str[i]; i++) {
if (islower((unsigned char)str[i]))
str[i] = toupper((unsigned char)str[i]);
else if (isupper((unsigned char)str[i]))
str[i] = tolower((unsigned char)str[i]);
}}
int main() {
int shmid;
char *shm;
key_t key = 1234;
shmid = shmget(key, SHM_SIZE, IPC_CREAT | 0666);
if (shmid < 0) {
perror("shmget");
exit(EXIT_FAILURE);
}
shm = (char *)shmat(shmid, NULL, 0);
if (shm == (char *)-1) {
perror("shmat");
exit(EXIT_FAILURE);
}
shm[0] = 0;
pid_t pid = fork();
if (pid < 0) {
perror("fork");
shmdt(shm);
shmctl(shmid, IPC_RMID, NULL);
exit(EXIT_FAILURE);
}
if (pid > 0) {
char str1[256], str2[256], str3[256];
printf("Enter first string: ");
fgets(str1, sizeof(str1), stdin);
str1[strcspn(str1, "\n")] = '\0';
printf("Enter second string: ");
fgets(str2, sizeof(str2), stdin);
str2[strcspn(str2, "\n")] = '\0';

printf("Enter third string: ");
fgets(str3, sizeof(str3), stdin);
str3[strcspn(str3, "\n")] = '\0';
snprintf(shm + 1, SHM_SIZE - 1, "%s\n%s\n%s", str1, str2, str3);
shm[0] = 1;
wait(NULL);
if (shm[0] == 2) {
char *result = shm + 1;
printf("\nConcatenated string: %s\n", result);
flip_case(result);
printf("Flipped case string: %s\n", result);
}
shmdt(shm);
shmctl(shmid, IPC_RMID, NULL);
}
else {
while (shm[0] != 1)
usleep(1000);
char buffer[SHM_SIZE];
strncpy(buffer, shm + 1, SHM_SIZE - 1);
buffer[SHM_SIZE - 1] = '\0';
char *lines[3] = {"", "", ""};
int i = 0;
char *token = strtok(buffer, "\n");
while (token && i < 3) {
lines[i++] = token;
token = strtok(NULL, "\n");
}
snprintf(shm + 1, SHM_SIZE - 1, "%s %s %s",
lines[0], lines[1], lines[2]);
shm[0] = 2;
shmdt(shm);
exit(EXIT_SUCCESS);
}
return 0;
}
