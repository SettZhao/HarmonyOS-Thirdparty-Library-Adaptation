/**
 * @file list.h
 * @brief Simple doubly-linked list implementation
 * Replacement for futils/futils.h list functionality
 */

#ifndef _LIST_H_
#define _LIST_H_

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Doubly-linked list node structure
 */
struct list_node {
    struct list_node *prev;
    struct list_node *next;
    int refcount;
};

/**
 * Get the container structure from a member pointer
 */
#define list_entry(ptr, type, member) \
    ((type *)((char *)(ptr) - offsetof(type, member)))

/**
 * Initialize a list node
 */
static inline void list_node_unref(struct list_node *node) {
    node->prev = node;
    node->next = node;
    node->refcount = 0;
}

/**
 * Initialize a list head
 */
static inline void list_init(struct list_node *head) {
    head->prev = head;
    head->next = head;
    head->refcount = 1;
}

/**
 * Check if node is referenced in a list
 */
static inline int list_node_is_ref(struct list_node *node) {
    return node->refcount > 0;
}

/**
 * Add a node after another node
 */
static inline void list_add_after(struct list_node *prev, struct list_node *node) {
    node->next = prev->next;
    node->prev = prev;
    prev->next->prev = node;
    prev->next = node;
    node->refcount = 1;
}

/**
 * Remove a node from list
 */
static inline void list_del(struct list_node *node) {
    if (node->refcount > 0) {
        node->prev->next = node->next;
        node->next->prev = node->prev;
        node->prev = node;
        node->next = node;
        node->refcount = 0;
    }
}

/**
 * Get the last node in a list
 */
static inline struct list_node *list_last(struct list_node *head) {
    return head->prev;
}

/**
 * Check if list is empty
 */
static inline int list_is_empty(struct list_node *head) {
    return head->next == head;
}

/**
 * Walk forward through list entries
 */
#define list_walk_entry_forward(head, pos, member) \
    for (pos = list_entry((head)->next, typeof(*pos), member); \
         &pos->member != (head); \
         pos = list_entry(pos->member.next, typeof(*pos), member))

/**
 * Walk forward through list entries (safe against removal)
 */
#define list_walk_entry_forward_safe(head, pos, tmp, member) \
    for (pos = list_entry((head)->next, typeof(*pos), member), \
         tmp = list_entry(pos->member.next, typeof(*pos), member); \
         &pos->member != (head); \
         pos = tmp, tmp = list_entry(tmp->member.next, typeof(*tmp), member))

#ifdef __cplusplus
}
#endif

#endif /* _LIST_H_ */
