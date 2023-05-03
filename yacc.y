%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

extern int yylex();
int yyerror();

int temp_var_num = 0;
int label_num=0;
int else_label_num = 0;
bool else_flag=0;
int bool_ir_index=100;
int bool_ir_start = 100;
int bool_ir_if_top=-1;
int bool_ir_if_stack[10];

int loop_stack_top=-1;
int loop_stack[10];

char bool_code[25][50];


struct three_address_code {
	char instr[4][20];
} tac[50];

int tac_len;

void addToThreeAddressArthmtc(char* op, char* arg1, char* arg2, char* result)
{
  strcpy(tac[tac_len].instr[0],result);
  strcpy(tac[tac_len].instr[1],arg1);
  strcpy(tac[tac_len].instr[2],arg2);
  strcpy(tac[tac_len].instr[3],op);
  tac_len++;
}

void addToThreeAddressBrnch(char *res)
{
  char *arg1 = "",*arg2 = "",*op = "",*result = "";

  char *init = strtok(res," ");
  if(res[0] == 'i')
  {
    arg1 = strtok(NULL," ");
    op = strtok(NULL, " ");
    arg2 = strtok(NULL, " ");
    strtok(NULL, " ");
    result = strtok(NULL, " ");
  }
  else if(res[0] == 'g')
  {
    op = init;
    result = strtok(NULL, " ");
  }
  else
    result = strtok(init,":");

  strcpy(tac[tac_len].instr[0],result);
  strcpy(tac[tac_len].instr[1],arg1);
  strcpy(tac[tac_len].instr[2],arg2);
  strcpy(tac[tac_len].instr[3],op);
  tac_len++;
}

void generate_code(char* op, char* arg1, char* arg2, char* result)
{
  //printf("%s = %s %s %s\n", result, arg1, op, arg2);
  addToThreeAddressArthmtc(op,arg1,arg2,result);
}

typedef struct B {
    int *t;
    int *f;
	int next_ir;
}B;

void generate_bool_oprtr() {
  int temp = bool_ir_start-100;
  while(temp<bool_ir_index-100) {
    addToThreeAddressBrnch(bool_code[temp]);
    temp++;
  }

  //TODO: Remove ":"

  char *buff = malloc(10*sizeof(char));
  sprintf(buff, "L%d:", temp); 
  addToThreeAddressBrnch(buff);
}

int *copy_list(int *source) {
  int *new = calloc(15,sizeof(int));
  int i=0;
  while(i<15 && source[i]!=0) {
    new[i] = source[i];
    i++;
  }
  while(i<15) {
    new[i] = 0;
    i++;
  }
  return new;
}

int *merge_list(int *list1,int *list2) {
  int* temp=calloc(15,sizeof(int)),count1=0,count2=0;
  
  while(list1[count1]!=0)
  {
    temp[count1]=list1[count1];
    count1++;
  }

  while(list2[count2]!=0)
  {
    temp[count1]=list2[count2];
    count2++;
  }
  return temp;
}

void backpatch(int *list,int next_ir) {
  char addr[10];
 
  sprintf(addr,"L%d ",next_ir-100);
 
  int i=0;
  while(list[i]!=0) {
    char label[50];
    strcat(bool_code[list[i]-100],addr);
    sprintf(label,"L%d: ",next_ir-100);
    strcat(label,bool_code[next_ir-100]);
    strcpy(bool_code[next_ir-100],label);
    i++;
  }
}

%}

%union{
	char string[50];	
	B *b;
}

%token INCLUDE INCL_FILE MACRO
%token TYPE IF ELSE VARIABLE CONSTANT
%token S_COMMENT M_COMMENT
%token FOR WHILE MAIN RETURN
%token LOGIC_OPRTR OPRTR_ASSGN UNARY OR AND
%token ERROR

%left '+' '-'
%left '*' '/'
%left LOGIC_OPRTR
%right '=' UMINUS
%left OR AND

%%
program: program_body
|
;

program_body:
  include program_body
| main
;

include: INCLUDE INCL_FILE

main: TYPE MAIN '(' ')' '{' body '}'

body: 
  body line
|
;

line:
	branch
  {
    if(else_flag)
    {

      char label[5] = {0}, buff[5] = {0};
      sprintf(buff,"%d",else_label_num);
      label[0] = 'G';
      strcat(label,buff);
      strcpy(tac[tac_len++].instr[0],label);

      else_flag=0;
      else_label_num++;
    }
  }
|	assignment ';'
|	declaration ';'
| loops
| RETURN CONSTANT ';'
;

declaration:
	TYPE varlist
;

varlist:
	vars ',' varlist
| vars
;

vars:
  VARIABLE
| assignment
;  

assignment:
	VARIABLE '=' arithmetic_oprtr   {addToThreeAddressArthmtc("",$<string>3,"",$<string>1);}

branch:
  if_else
| if
;

/* TODO: C like for loops */

loops:
  WHILE '(' bool_oprtr ')' block
| FOR '(' declaration ';' bool_oprtr ';' unary ')' block
| FOR '(' assignment ';' bool_oprtr ';' unary ')' block
;

unary:
  VARIABLE UNARY
| UNARY VARIABLE
|
;

if: IF '(' bool_oprtr ')' 
    {
      backpatch($<b>3->t,bool_ir_index); 
      backpatch($<b>3->f,bool_ir_index+1);
      generate_bool_oprtr();
      bool_ir_if_top++;
      bool_ir_if_stack[bool_ir_if_top] = ++bool_ir_index;
      bool_ir_start = bool_ir_index;
    }
    block
    {
      char buff[10];
      sprintf(buff, "L%d:",bool_ir_if_stack[bool_ir_if_top]-100); 
      addToThreeAddressBrnch(buff);
      bool_ir_if_stack[bool_ir_if_top] = 0;
      bool_ir_if_top-=1;
    }



if_else:
	if ELSE
  {
    //TODO: Try making a getLabel function
    
    char label[5] = {0}, buff[5] = {0};
    sprintf(buff,"%d",else_label_num);
    label[0] = 'G';
    strcat(label,buff);

    strcpy(tac[tac_len].instr[0], tac[tac_len-1].instr[0]);
    strcpy(tac[tac_len].instr[1], tac[tac_len-1].instr[1]);
    strcpy(tac[tac_len].instr[2], tac[tac_len-1].instr[2]);
    strcpy(tac[tac_len].instr[3], tac[tac_len-1].instr[3]);
    
    strcpy(tac[tac_len-1].instr[0], label);
    strcpy(tac[tac_len-1].instr[3], "goto");
    else_flag = 1;
    tac_len++;
  } 
  block
| if ELSE 
  {
    //TODO: Try making a getLabel function
    
    char label[5] = {0}, buff[5] = {0};
    sprintf(buff,"%d",else_label_num);
    label[0] = 'G';
    strcat(label,buff);

    strcpy(tac[tac_len].instr[0], tac[tac_len-1].instr[0]);
    strcpy(tac[tac_len].instr[1], tac[tac_len-1].instr[1]);
    strcpy(tac[tac_len].instr[2], tac[tac_len-1].instr[2]);
    strcpy(tac[tac_len].instr[3], tac[tac_len-1].instr[3]);
    
    strcpy(tac[tac_len-1].instr[0], label);
    strcpy(tac[tac_len-1].instr[3], "goto");
    else_flag=1;
    tac_len++;
  }
  branch
;


block: '{' body '}'

arithmetic_oprtr:
  arithmetic_oprtr '+' arithmetic_oprtr
  {
    char *buff = calloc(10,sizeof(char)),*temp = calloc(10,sizeof(char));
    temp[0] = 't';
		sprintf(buff,"%d",temp_var_num++);
		strcat(temp,buff);
    generate_code("+", $<string>1, $<string>3, temp);
		strcpy($<string>$,temp);
  }
| arithmetic_oprtr '-' arithmetic_oprtr
{
    char *buff = calloc(10,sizeof(char)),*temp = calloc(10,sizeof(char));
    temp[0] = 't';
		sprintf(buff,"%d",temp_var_num++);
		strcat(temp,buff);
    generate_code("-", $<string>1, $<string>3, temp);
		strcpy($<string>$,temp);
}
| arithmetic_oprtr '*' arithmetic_oprtr
  {
    char *buff = calloc(10,sizeof(char)),*temp = calloc(10,sizeof(char));
    temp[0] = 't';
		sprintf(buff,"%d",temp_var_num++);
		strcat(temp,buff);
    generate_code("*", $<string>1, $<string>3, temp);
		strcpy($<string>$,temp);
  }
| arithmetic_oprtr '/' arithmetic_oprtr
  {
    char *buff = calloc(10,sizeof(char)),*temp = calloc(10,sizeof(char));
    temp[0] = 't';
		sprintf(buff,"%d",temp_var_num++);
		strcat(temp,buff);
    generate_code("/", $<string>1, $<string>3, temp);
		strcpy($<string>$,temp);   
  }
| '-' arithmetic_oprtr %prec UMINUS     {strcpy($<string>$,$<string>2);}
| '(' arithmetic_oprtr ')'              {strcpy($<string>$,$<string>2);}
| VARIABLE                              {strcpy($<string>$,$<string>1);}
| CONSTANT                              {strcpy($<string>$,$<string>1);}
;

bool_oprtr:
  bool_oprtr AND M bool_oprtr
  {
    B *b = calloc(1,sizeof(B)); 
    backpatch($<b>1->t,$<b>3->next_ir);
    b->t = copy_list($<b>4->t);
    b->f = merge_list($<b>1->f,$<b>4->f);
    $<b>$ = b;
  }
| bool_oprtr OR M bool_oprtr
  {
    B *b = calloc(1,sizeof(B)); 
    backpatch($<b>1->t,$<b>3->next_ir);
    b->t = copy_list($<b>4->t);
    b->f = merge_list($<b>1->f,$<b>4->f);
    $<b>$ = b;
  }
| '(' bool_oprtr ')'            {$<b>$ = $<b>2;}
| logic_oprtr                   {$<b>$ = $<b>1;}       
;

M: {B *b = calloc(1,sizeof(B)); b->next_ir = bool_ir_index; $<b>$ = b;}
;

logic_oprtr:
  arithmetic_oprtr LOGIC_OPRTR arithmetic_oprtr
  {
    B *b = calloc(1,sizeof(B));
    b->t = calloc(15,sizeof(int));
    b->t[0] = bool_ir_index;
    sprintf(bool_code[bool_ir_index-100],"if %s %s %s goto ",$<string>1,$<string>2,$<string>3);
    bool_ir_index++;

    b->f = calloc(15,sizeof(int));
    b->f[0] = bool_ir_index;
    sprintf(bool_code[bool_ir_index-100],"goto ");
    bool_ir_index++;

    $<b>$ = b;
  }
;

%%
#include "myLexHeader.h"

int main(void)
{
	if(!yyparse())
  {
    for(int i=0;i<tac_len;i++)
    {
      char *res = tac[i].instr[0];
      char *arg1 = tac[i].instr[1];
      char *arg2 = tac[i].instr[2];
      char *op = tac[i].instr[3];

      if(res[0] == 'L' || res[0] == 'G')
      {
        if(op[0] == 'g')
          printf("%s %s\n", op, res);
        else if(op[0] == '\0')
          printf("%s:\n", res);
        else
          printf("if %s %s %s goto %s\n", arg1, op, arg2, res);
      }
      else
        printf("%s = %s %s %s\n", res,arg1,op,arg2);
    }
    printf("completed!\n");
  }
	else
		printf("failed!\n");
	return 0;
}

int yyerror(char *s)
{
	printf("%d : %s %s\n",yylineno,s,yytext);
	return 1;
}
