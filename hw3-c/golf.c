#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// struct for GolfPlayer
typedef struct GolfPlayer{ // typedef is why you can refer to struct without having to use struct keyword
    char playerName[64];
    int score;
    struct GolfPlayer* next;
} GolfPlayer;

// print list
void printList(GolfPlayer* head){ 
    while(head != NULL){  // loop through the linkedlist
        if ((head -> score) > 0){ // if score is greater than zero, make sure to print with a plus sign
            printf("%s +%d\n", head->playerName, head->score);
        }
        else{ // if score is less than 1, print regularly 
            printf("%s %d\n", head->playerName, head->score);
        }

        GolfPlayer* temp = head; // free your memory through lines 22-24
        head = head -> next;
        free(temp);
    }
}

// compare players
int compare(GolfPlayer* a, GolfPlayer* b){
    if (a->score < b->score){ // if a comes before b, return -1
        return -1;
    }
    else if (a->score > b->score){ // if a comes after b, return +1
        return +1;
    }
    // check strings
    // if they have the same score, check name
    return strcmp(a->playerName, b->playerName); // if a comes before b alphabetically, return -1. 
    // if b comes before a alphabetically, return 1. if the two players have the same name, return 0.

}

// insertPlayers
GolfPlayer* insertPlayer(GolfPlayer* head, GolfPlayer* newPlayer){ // structure copied from basketball2.c from recitation 3
    if(head == NULL){ // if head is NULL, we know that newPlayer needs to be the new head
	newPlayer -> next = head;
        return newPlayer; // newPlayer is the new head
    }
    if(compare(newPlayer, head) <= 0){ // if newPlayer comes before head, newPlayer needs to be the new head
        newPlayer -> next = head; // because newPlayer is a pointer, use an arrow and not a point
        return newPlayer; // newPlayer is the new head
    }

    GolfPlayer* ptr = head; // use ptr to traverse the list

    while(ptr -> next != NULL){ // traverse until the node after ptr is NULL
        if (compare(newPlayer, ptr -> next) <= 0){ 
            newPlayer -> next = ptr -> next;
            ptr -> next = newPlayer;
            return head;
        }
        ptr = ptr -> next;
    }
     // if we traverse the entire list and still haven't inserted it, add to the end
     ptr -> next = newPlayer;
     newPlayer -> next = NULL;
     return head;
}

// main function that asks for input

int main(int argc, char* argv[]){
    FILE *file = fopen(argv[1], "r"); // open the file; argv[0] is the instruction, argv[2] is the file on command line
    int par; // initialize an int; this'll store the par
    fscanf(file, "%d", &par);

    GolfPlayer* sorted = NULL; 

    while (1){
        char name[64]; // char array that stores golfer's name
        int score; // initialize an int; this'll score the # of shots taken by golfer of name

        fscanf(file, "%s", name); // scan the next line of file; assume that it's name

        if (strcmp(name, "DONE") == 0){ // checks if "DONE" is actually what name is
            break; // if so, exit loop. that means there are no more lines to check.
        }

        fscanf(file, "%d", &score); // if we the name wasn't "DONE", then we can scan the next line
        score = score - par; // recalculate score

        // allocate memory for a new node
        GolfPlayer* newPlayer = (GolfPlayer*) malloc(sizeof(GolfPlayer)); // make space for new player
        
        strcpy(newPlayer->playerName, name); // copy name to the actual destination of the node
        newPlayer -> score = score; // NOTE to self, different from python! we use arrows because this is a pointer, when you use pointers, you have to use the arrow
        // when you use arrows, you can't use the dot operator

        sorted = insertPlayer(sorted, newPlayer);
        //ptr -> next = newPlayer;
        //ptr = ptr->next;
    }
    
    printList(sorted); // print your sorted list

    fclose(file); // close the file
    return 0; // if you don't have this line you'll run into issues
}