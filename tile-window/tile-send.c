#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char **argv) {
  if (argc < 2) {
    return 1;
  }
  const char *home = getenv("HOME");
  if (!home) {
    return 1;
  }
  char path[512];
  snprintf(path, sizeof(path), "%s/.config/karabiner/scripts/tile-window.fifo", home);
  int fd = -1;
  for (int i = 0; i < 20 && fd < 0; i++) {
    fd = open(path, O_WRONLY | O_NONBLOCK);
    if (fd < 0) {
      usleep(25000);
    }
  }
  if (fd < 0) {
    return 1;
  }
  write(fd, argv[1], strlen(argv[1]));
  close(fd);
  return 0;
}
