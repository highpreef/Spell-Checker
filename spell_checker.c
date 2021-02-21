/***********************************************************************
* File       : <spell_checker.c>
*
* Author     : <Siavash Katebzadeh>
*
* Description: 
*
* Date       : 08/10/18
*
***********************************************************************/
// ==========================================================================
// Spell checker 
// ==========================================================================
// Marks misspelled words in a sentence according to a dictionary

// Inf2C-CS Coursework 1. Task B/C 
// PROVIDED file, to be used as a skeleton.

// Instructor: Boris Grot
// TA: Siavash Katebzadeh
// 08 Oct 2018

#include <stdio.h>

// maximum size of input file
#define MAX_INPUT_SIZE 2048
// maximum number of words in dictionary file
#define MAX_DICTIONARY_WORDS 10000
// maximum size of each word in the dictionary
#define MAX_WORD_SIZE 20

int read_char() { return getchar(); }
int read_int()
{
    int i;
    scanf("%i", &i);
    return i;
}
void read_string(char* s, int size) { fgets(s, size, stdin); }

void print_char(int c)     { putchar(c); }   
void print_int(int i)      { printf("%i", i); }
void print_string(char* s) { printf("%s", s); }
void output(char *string)  { print_string(string); }

// dictionary file name
char dictionary_file_name[] = "dictionary.txt";
// input file name
char input_file_name[] = "input.txt";
// content of input file
char content[MAX_INPUT_SIZE + 1];
// valid punctuation marks
char punctuations[] = ",.!?";
// tokens of input file
char tokens[MAX_INPUT_SIZE + 1][MAX_INPUT_SIZE + 1];
// number of tokens in input file
int tokens_number = 0;
// content of dictionary file
char dictionary[MAX_DICTIONARY_WORDS * MAX_WORD_SIZE + 1];

///////////////////////////////////////////////////////////////////////////////
/////////////// Do not modify anything above
///////////////////////////////////////////////////////////////////////////////

// You can define your global variables here!

// Array with checked tokens (accounts for succeeding and preceding '_')
char checked_tokens[MAX_INPUT_SIZE + 1][MAX_INPUT_SIZE + 3];

// Functions

// ToLower function returns the lowercase version of an input char
char toLower(char c) { 
  if (c >= 'A' && c <= 'Z') {
      c = c + 32;
    }
  return c;
}

// Match function takes the indexes from the current dictionary word and the tokens array. Returns a boolean if it matches the current token or not
_Bool match(int idx, int token_idx, int token_c_idx, char c) {
  
  // Returned boolean
  _Bool match = 0;

  // For loop variable
  int i;

  // Loop that runs through both the token and the dictionary word to check if they match
  for (i = 0; i < MAX_WORD_SIZE+1; ++i) { 

    // Break if words don't match      
    if (dictionary[i+idx] != c) {
      break;            
    }

    // If chars at the same position match move to next position
    if (dictionary[i+idx] == c) {
      ++token_c_idx;
      c = tokens[token_idx][token_c_idx];
      c = toLower(c);  
    } 

    // If a match for the token was found return 1 to function call
    if (dictionary[i+idx+1] == '\n' && c == '\0') {
      match = 1;
      break;
    } 

    // If dictionary word was a part of the token, break
    if (dictionary[i+idx+1] == '\n' && c != '\0') {
      break;
    }

  }
  return match;

}

// Store function stores the token in the checked_tokens array with '_' chars where necessary
void store(int token_idx, _Bool correct) {

  // For loop variable
  int i;

  // If token had a match copy 'as is' to checked_tokens array
  if (correct) {
    for (i = 0; i < MAX_INPUT_SIZE+1; ++i) {
      if (tokens[token_idx][i] != '\0') {
        checked_tokens[token_idx][i] = tokens[token_idx][i];
      }
      if (tokens[token_idx][i] == '\0') {
        checked_tokens[token_idx][i] = '\0';
        break;
      }
    }

  // If token was not in dictionary add required '_' chars
  } else if (!correct) {
      for (i = 0; i < MAX_INPUT_SIZE+1; ++i) {
        if (tokens[token_idx][i] == '\0') {
          checked_tokens[token_idx][i] = tokens[token_idx][i-1];
          checked_tokens[token_idx][i+1] = '_';
          checked_tokens[token_idx][i+2] = '\0';
          break;
        } else if (i == 0) {
              checked_tokens[token_idx][i] = '_';
        } else if (i > 0) {
            checked_tokens[token_idx][i] = tokens[token_idx][i-1];
        }
      }
  }

  return;
}


// Task B

void spell_checker() {

  // For loop variable
  int i;
  
  // Token array row
  int c_idx = 0; 
  
  // Token array column
  int token_c_idx;

  // Current token char
  char c;

  // Correct spelling boolean
  _Bool correct;
  
  do {

    //For every token checked, column index and boolean are reset
    token_c_idx = 0;
    correct = 0;

    // Load token char
    c = tokens[c_idx][token_c_idx];

    // Make checking case insensitive
    c = toLower(c);

    // End of tokens array
    if((tokens[c_idx][token_c_idx] == '\0')) {
      checked_tokens[c_idx][token_c_idx] = '\0';
      break;
    }
    
    // If not alphanumeric word increase row index and load token into checked_tokens array
    if(c == ' ' || c == '.' || c == ',' || c == '!' || c == '?') {

      // Store non alphanumeric 'as is' to checked_tokens array
      correct = 1;
      store(c_idx, correct);
      ++c_idx;

    // If alphanumeric, start brute force search through the dictionary
    } else if (c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z') {

        for (i = 0; i < MAX_DICTIONARY_WORDS * MAX_WORD_SIZE + 1; ++i) {

          // First dictionary word case
          if ((i == 0)) {

            // Check if current dictionary word matches token, changing boolean accordingly
            if (match(i, c_idx, token_c_idx, c)) {
              correct = 1;
              break;
            }
          }

          // All other cases
          if (dictionary[i] == '\n') {

            // Check if current dictionary word matches token, changing boolean accordingly
            if (match(i+1, c_idx, token_c_idx, c)) {
              correct = 1;
              break;
            }
          }
        }

        // store token in checked_tokens array
        store(c_idx, correct);

        // Move to next token
        ++c_idx;

      }

  } while(1);

  return;
}


// Task B

// Prints all checked tokens one after the other
void output_tokens() {

  // for loop variable
  int i;

  for (i = 0; i < tokens_number; ++i) {
    output(checked_tokens[i]);  
  }
  return;
}

//---------------------------------------------------------------------------
// Tokenizer function
// Split content into tokens
//---------------------------------------------------------------------------
void tokenizer(){
  char c;

  // index of content 
  int c_idx = 0;
  c = content[c_idx];
  do {

    // end of content
    if(c == '\0'){
      break;
    }

    // if the token starts with an alphabetic character
    if(c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z') {
      
      int token_c_idx = 0;
      // copy till see any non-alphabetic character
      do {
        tokens[tokens_number][token_c_idx] = c;

        token_c_idx += 1;
        c_idx += 1;

        c = content[c_idx];
      } while(c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z');
      tokens[tokens_number][token_c_idx] = '\0';
      tokens_number += 1;

      // if the token starts with one of punctuation marks
    } else if(c == ',' || c == '.' || c == '!' || c == '?') {
      
      int token_c_idx = 0;
      // copy till see any non-punctuation mark character
      do {
        tokens[tokens_number][token_c_idx] = c;

        token_c_idx += 1;
        c_idx += 1;

        c = content[c_idx];
      } while(c == ',' || c == '.' || c == '!' || c == '?');
      tokens[tokens_number][token_c_idx] = '\0';
      tokens_number += 1;

      // if the token starts with space
    } else if(c == ' ') {
      
      int token_c_idx = 0;
      // copy till see any non-space character
      do {
        tokens[tokens_number][token_c_idx] = c;

        token_c_idx += 1;
        c_idx += 1;

        c = content[c_idx];
      } while(c == ' ');
      tokens[tokens_number][token_c_idx] = '\0';
      tokens_number += 1;
    }
  } while(1);
}
//---------------------------------------------------------------------------
// MAIN function
//---------------------------------------------------------------------------

int main (void)
{


  /////////////Reading dictionary and input files//////////////
  ///////////////Please DO NOT touch this part/////////////////
  int c_input;
  int idx = 0;
  
  // open input file 
  FILE *input_file = fopen(input_file_name, "r");
  // open dictionary file
  FILE *dictionary_file = fopen(dictionary_file_name, "r");

  // if opening the input file failed
  if(input_file == NULL){
    print_string("Error in opening input file.\n");
    return -1;
  }

  // if opening the dictionary file failed
  if(dictionary_file == NULL){
    print_string("Error in opening dictionary file.\n");
    return -1;
  }

  // reading the input file
  do {
    c_input = fgetc(input_file);
    // indicates the the of file
    if(feof(input_file)) {
      content[idx] = '\0';
      break;
    }
    
    content[idx] = c_input;

    if(c_input == '\n'){
      content[idx] = '\0'; 
    }

    idx += 1;

  } while (1);

  // closing the input file
  fclose(input_file);

  idx = 0;

  // reading the dictionary file
  do {
    c_input = fgetc(dictionary_file);
    // indicates the end of file
    if(feof(dictionary_file)) {
      dictionary[idx] = '\0';
      break;
    }
    
    dictionary[idx] = c_input;
    idx += 1;
  } while (1);

  // closing the dictionary file
  fclose(dictionary_file);
  //////////////////////////End of reading////////////////////////
  ////////////////////////////////////////////////////////////////

  tokenizer();
  
  spell_checker();
  
  output_tokens();

  return 0;
}
