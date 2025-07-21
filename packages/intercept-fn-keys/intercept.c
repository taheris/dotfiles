#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <linux/input.h>

static void send_event(int type, int code, int value, struct timeval time) {
    struct input_event event = {
        .time = time,
        .type = type,
        .code = code,
        .value = value
    };

    if (fwrite(&event, sizeof(event), 1, stdout) != 1) {
        fprintf(stderr, "Error writing event: %s\n", strerror(errno));
        exit(EXIT_FAILURE);
    }
}

static void handle_f17_key(const struct input_event *event) {
    switch (event->value) {
    case 1:  // Key press
        send_event(event->type, event->code, event->value, event->time);
        break;

    case 2:  // Key repeat - ignore
        break;

    case 0:  // Key release - send F17 release, then F18 tap
        send_event(EV_KEY, KEY_F17, 0, event->time);
        send_event(EV_SYN, SYN_REPORT, 0, event->time);
        send_event(EV_KEY, KEY_F18, 1, event->time);
        send_event(EV_SYN, SYN_REPORT, 0, event->time);
        send_event(EV_KEY, KEY_F18, 0, event->time);
        send_event(EV_SYN, SYN_REPORT, 0, event->time);
        break;

    default:
        fprintf(stderr, "Unexpected key value: %d\n", event->value);
        break;
    }
}

int main(void) {
    struct input_event event;

    // Disable buffering for real-time processing
    setbuf(stdin, NULL);
    setbuf(stdout, NULL);

    while (fread(&event, sizeof(event), 1, stdin) == 1) {
        if (event.type == EV_KEY && event.code == KEY_F17) {
            handle_f17_key(&event);
        } else {
            // Pass through all other events
            if (fwrite(&event, sizeof(event), 1, stdout) != 1) {
                fprintf(stderr, "Error writing event: %s\n", strerror(errno));
                return EXIT_FAILURE;
            }
        }
    }

    if (ferror(stdin)) {
        fprintf(stderr, "Error reading input: %s\n", strerror(errno));
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
