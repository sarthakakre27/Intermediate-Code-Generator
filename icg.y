%{
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

struct expression_type{

	char* addr;
	char* code;
	
};
extern int yylineno; //for error line printing
int num_temp = 1;	//Stores the number of the last temporary variable used
int num_label = 1; //Stores the number of the last label used
char* var;
char buffer_temporary_num_concat[10]; //buffers to generate temporary and label
char buffer_label_num_concat[10];
char* return_val;
char* temp;
char* label; //variables for storing label strings
char* label2;
char* check;//variables for backpatch
char* begin_construct_label;
char* temp;
char* b1;//variables for storing boolean strings
char* b2;
char* s1;//variables for storing statement strings
char* s2;
struct expression_type* expression_ret;	//To store the code and address corresponding to generation of expression and statements
void yyerror(char* s);// function for error handling
int yylex(void);

//Function to generate new temporary variables
char* generateNewTemporary()
{
	char* new_temporary = (char*)malloc(20);
	strcpy(new_temporary,"t");
	buffer_temporary_num_concat[0]=0;
	snprintf(buffer_temporary_num_concat, 10,"%d",num_temp);
	strcat(new_temporary,buffer_temporary_num_concat);
	num_temp++;
	return new_temporary;
}

//Function to generate new labels
char* generateNewLabel()
{
	char* new_label = (char*)malloc(20);
	strcpy(new_label,"L");
	snprintf(buffer_label_num_concat, 10,"%d",num_label);
	strcat(new_label,buffer_label_num_concat);
	num_label++;
	return new_label;
}

//Function to replace a substring str with another substring label in the original string s1 which is backpatch function
void backpatch(char* s1,char* str, char* label)
{
	char* check = strstr (s1,str);
	while(check!=NULL)
	{
		strncpy (check, label,strlen(label));
		strncpy (check + strlen(label), "    ", (4-strlen(label)));
		check = strstr(s1,str);
	}
}
%}

%start Start
%union {
	int int_val;
	float float_val;
	char* string_val;
	struct expression_type* EXPRTYPE;
}

%token<int_val> DIGIT
%token<float_val> FLOAT
%token<string_val> ID IF ELSE WHILE TYPES  REL_OPT OR AND NOT PE ME INCR DEFAULT DECR TRUE FALSE BREAK FOR
%token<string_val> '+' '-' '*' '/' '^' '%' '\n' '=' ';' ':' '&' '|' ','
%type<string_val> list_stats text number construct  block_stats dec boolean program Start
%type<EXPRTYPE> expression stat list_expr unary

%left OR
%left AND
%left NOT
%left REL_OPT
%left '|' '&' '^'
%right '='
%left '+' '-'
%left '*' '/' '%'
%%

Start:	program
		{
			s1 = $1;
			label = generateNewLabel();
			backpatch(s1,"NEXT",label);
			return_val = (char*)malloc(strlen(s1) + 50);
			return_val[0] = 0;
			strcat(return_val,s1);
			strcat(return_val,"\n");
			strcat(return_val,label);
			strcat(return_val," : END OF THREE ADDRESS CODE !!!!!\n");
			printf("\n----------  FINAL THREE ADDRESS CODE ----------\n");
			puts(return_val);
			$$ = return_val;
		}
		;

program : 	program construct
		{
			s1 = $1;
			s2 = $2;
			label = generateNewLabel();
			backpatch(s1,"NEXT",label);
			return_val = (char*)malloc(strlen($1)+strlen($2)+4);
			return_val[0] = 0;
			strcat(return_val,$1);
			strcat(return_val,"\n");
			strcat(return_val,label);
			strcat(return_val," : ");
			strcat(return_val,$2);
			$$ = return_val;
		}
		|
		construct
		{
			$$ = $1;
		}
		;

construct :     block_stats
		{
			$$ = $1;
		}
		|
		WHILE '(' boolean ')' block_stats 
		{
			
			b1 = $3;
			s1 = $5;
			label = generateNewLabel();
			backpatch(b1,"TRUE",label);
			backpatch(b1,"FAIL","NEXT");
			begin_construct_label = generateNewLabel();
			backpatch(s1,"NEXT",begin_construct_label);
			return_val = (char*)malloc(strlen(b1)+strlen(s1)+200);
			return_val[0] = 0;
			strcat(return_val,begin_construct_label);
			strcat(return_val," : ");
			strcat(return_val,b1);
			strcat(return_val,"\n");
			strcat(return_val,label);
			strcat(return_val," : ");
			strcat(return_val,s1);
			strcat(return_val,"\n");
			strcat(return_val,"goto ");
			strcat(return_val,begin_construct_label);
			$$ = return_val;
	
		}
		|
		IF '(' boolean ')' block_stats
		{
			label = generateNewLabel();
			b1 = $3;
			backpatch(b1,"TRUE",label);
			backpatch(b1,"FAIL","NEXT");
			check = strstr(b1,"FAIL");
			return_val = (char*)malloc(strlen(b1)+strlen($5)+4);
			return_val[0] = 0;
			strcat(return_val,b1);
			strcat(return_val,"\n");
			strcat(return_val,label);
			strcat(return_val," : ");
			strcat(return_val,$5);
			printf("Printing return_val \n");
			$$ = return_val;
		}
		|
		IF '(' boolean ')' block_stats ELSE block_stats
		{
			b1 = $3;
			label = generateNewLabel();
			backpatch(b1,"TRUE",label);
			label2 = generateNewLabel();
			backpatch(b1,"FAIL",label2);
			return_val = (char*)malloc(strlen(b1)+strlen($5)+strlen($7)+20);
			return_val[0] = 0;
			strcat(return_val,b1);strcat(return_val,"\n");
			strcat(return_val,label);
			strcat(return_val," : ");
			strcat(return_val,$5);
			strcat(return_val,"\n");
			strcat(return_val,"goto NEXT");
			strcat(return_val,"\n");
			strcat(return_val,label2);
			strcat(return_val," : ");
			strcat(return_val,$7);
			$$ = return_val;
		}
		|
		FOR '(' list_expr ';'  boolean ';' list_expr ')' block_stats
		{
			b1 = $5;
			s1 = $9;
			label = generateNewLabel();
			backpatch(b1,"TRUE",label);
			backpatch(b1,"FAIL","NEXT");
			begin_construct_label = generateNewLabel();
			backpatch(s1,"NEXT",begin_construct_label);
			return_val = (char*)malloc(strlen(b1) + strlen(s1) + strlen($3->code) + strlen($7->code) + 200);
			return_val[0] = 0;
			strcat(return_val,$3->code);
			strcat(return_val,"\n");
			strcat(return_val,begin_construct_label);strcat(return_val," : ");
			strcat(return_val,b1);strcat(return_val,"\n");
			strcat(return_val,label);strcat(return_val," : ");
			strcat(return_val,s1);
			strcat(return_val,"\n");
			strcat(return_val,$7->code);
			strcat(return_val,"\n");
			strcat(return_val,"goto ");
			strcat(return_val,begin_construct_label);
			$$ = return_val;
		}
		;

block_stats:	'{' list_stats '}'
		{
			$$ = $2;
		}
		|
		'{' program '}'
		{
			$$ = $2;
		}
		|
		list_stats 
		{
			$$ = $1;
		}
		;
	 

list_stats:   stat
		{
			$$ = $1->code;
		}
        |
        list_stats stat
		{
			return_val = (char*)malloc(strlen($1) + strlen($2->code) + 4);
			return_val[0] = 0;
			strcat(return_val,$1);
			strcat(return_val,"\n");
			strcat(return_val,$2->code);
			$$ = return_val;
		}
	 	|
        list_stats error '\n'
        {
        	yyerrok;
        }
        ;


stat:   ';'
	 	{
			expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(20);
			expression_ret->addr = $1;
			expression_ret->code = (char*)malloc(2);
			expression_ret->code[0] = 0;
			$$ = expression_ret;
	 	}
	 	|
	 	unary 
	 	{
			 $$ = $1;
	 	}
	 	|
	 	dec ';'
        {
			expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(200);
			expression_ret->addr = $1;
			expression_ret->code = (char*)malloc(2);
			expression_ret->code[0] = 0;
			$$ = expression_ret;
        }
		|
        text '=' expression ';'
        {
			expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(200);
			expression_ret->addr = generateNewTemporary();
			return_val = (char*)malloc(20);
			return_val[0] = 0;
			strcat(return_val,$1);strcat(return_val,"=");
			strcat(return_val,$3->addr);
			temp = (char*)malloc(strlen($3->code)+strlen(return_val)+60);
			temp[0] = 0;
			if ($3->code[0]!=0)
			{
				strcat(temp,$3->code);
				strcat(temp,"\n");
			}
			strcat(temp,return_val);
			expression_ret->code = temp;
			$$ = expression_ret;
        }
        |
        text PE expression ';'
        {
	        expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(20);
			expression_ret->addr = generateNewTemporary();
			return_val = (char*)malloc(200);
			return_val[0] = 0;
			strcat(return_val,$1);
			strcat(return_val,"="); 
			strcat(return_val,$1);
			strcat(return_val,"+"); 
			strcat(return_val,$3->addr); 
			strcat(return_val,"\n");
			strcat(return_val,expression_ret->addr); 
			strcat(return_val,"=");
			strcat(return_val,$1);
			temp = (char*)malloc(strlen($3->code) + strlen(return_val)+60);
			temp[0] = 0;
			if ($3->code[0]!=0)
			{
				strcat(temp,$3->code);
				strcat(temp,"\n");
			}
			strcat(temp,return_val);
			expression_ret->code = temp;
			$$ = expression_ret;
         }
         |
         text ME expression ';'
         {
			expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(20);
			expression_ret->addr = generateNewTemporary();
			return_val = (char*)malloc(20);
			return_val[0] = 0;
			strcat(return_val,$1);
			strcat(return_val,"="); 
			strcat(return_val,$1);
			strcat(return_val,"-"); 
			strcat(return_val,$3->addr);
			strcat(return_val,"\n");
			strcat(return_val,expression_ret->addr); 
			strcat(return_val,"=");
			strcat(return_val,$1);
			temp = (char*)malloc(strlen($3->code)+strlen(return_val)+6);
			temp[0] = 0;
			
			if ($3->code[0]!=0)
			{
				strcat(temp,$3->code);
				strcat(temp,"\n");
			}
			strcat(temp,return_val);
			expression_ret->code = temp;
			$$ = expression_ret;
        }
	 	|
	 	dec '=' expression ';'
        {
			expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(200);
			expression_ret->addr = generateNewTemporary();
			return_val = (char*)malloc(200);
			return_val[0] = 0;
			strcat(return_val,$1);
			strcat(return_val,"=");
			strcat(return_val,$3->addr);
			temp = (char*)malloc(strlen($1)+strlen($3->code)+strlen(return_val)+6);
			temp[0] = 0;
			if ($3->code[0]!=0)
			{
				strcat(temp,$3->code);
				strcat(temp,"\n");
			}
			strcat(temp,return_val);
			expression_ret->code = temp;
			$$ = expression_ret;
        }
        ;

unary : text INCR
		{
			expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(20);
			expression_ret->addr = generateNewTemporary();
			return_val = (char*)malloc(20);
			return_val[0] = 0;
			strcat(return_val,expression_ret->addr);
			strcat(return_val,"=");
			strcat(return_val,$1);
			strcat(return_val,"\n"); 
			strcat(return_val,$1); 
			strcat(return_val,"=");
			strcat(return_val,$1);
			strcat(return_val,"+1");
			temp = (char*)malloc(strlen(return_val)+20);temp[0] = 0;
			strcat(temp,return_val);
			expression_ret->code = temp;
			$$ = expression_ret;

		}
		|
		text DECR
		{
			expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(20);
			expression_ret->addr = generateNewTemporary();
			return_val = (char*)malloc(20);
			return_val[0] = 0;
			strcat(return_val,expression_ret->addr);strcat(return_val,"=");
			strcat(return_val,$1);
			strcat(return_val,"\n"); 
			strcat(return_val,$1); 
			strcat(return_val,"=");
			strcat(return_val,$1);
			strcat(return_val,"-1");
			temp = (char*)malloc(strlen(return_val)+20);
			temp[0] = 0;
			strcat(temp,return_val);
			expression_ret->code = temp;
			$$ = expression_ret;

		}
		|
		INCR text
		{
			
	        expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(20);
			expression_ret->addr = generateNewTemporary();
			return_val = (char*)malloc(20);
			return_val[0] = 0;
			strcat(return_val,$2);
			strcat(return_val,"=");
			strcat(return_val,$2);
			strcat(return_val,"+1");
			strcat(return_val,"\n");
			strcat(return_val,expression_ret->addr);
			strcat(return_val,"=");
			strcat(return_val,$2);
			temp = (char*)malloc(strlen(return_val)+20);
			temp[0] = 0;
			strcat(temp,return_val);
			expression_ret->code = temp;
			$$ = expression_ret;

		}
		|
		DECR text

		{
			expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(20);
			expression_ret->addr = generateNewTemporary();
			return_val = (char*)malloc(20);
			return_val[0] = 0;
			strcat(return_val,$2);
			strcat(return_val,"=");
			strcat(return_val,$2);
			strcat(return_val,"-1");
			strcat(return_val,"\n");
			strcat(return_val,expression_ret->addr);
			strcat(return_val,"=");
			strcat(return_val,$2);
			temp = (char*)malloc(strlen(return_val)+20);
			temp[0] = 0;
			strcat(temp,return_val);
			expression_ret->code = temp;
			$$ = expression_ret;

		}
		;

dec : 	TYPES text 
		{	
			$$ = $2;
		}
		;

boolean : 	expression REL_OPT expression
		{
			temp = (char*)malloc(strlen($1->code)+strlen($3->code)+50);
			temp[0] = 0;
			if($1->code[0]!=0)
			{
				strcat(temp,$1->code);
				strcat(temp,"\n");
			}
			if($3->code[0]!=0)
			{
				strcat(temp,$3->code);
				strcat(temp,"\n");
			}
			return_val = (char*)malloc(50);
			return_val[0] = 0;
			strcat(return_val,"if(");
			strcat(return_val,$1->addr);
			strcat(return_val,$2);
			strcat(return_val,$3->addr);
			strcat(return_val,") goto TRUE \n goto FAIL");
			strcat(temp,return_val);
			$$ = temp;
		}
		|
		boolean OR boolean
		{
			b1 = $1;
			b2 = $3;
			label = generateNewLabel();
			backpatch(b1,"FAIL",label);
			temp = (char*)malloc(strlen(b1)+strlen(b2)+10);
			temp[0] = 0;
			strcat(temp,b1);
			strcat(temp,"\n");
			strcat(temp,label);
			strcat(temp," : ");
			strcat(temp,b2);
			$$ = temp;
		}
		|
		boolean AND boolean
		{
			b1 = $1;
			b2 = $3;
			label = generateNewLabel();
			backpatch(b1,"TRUE",label);
			temp = (char*)malloc(strlen(b1)+strlen(b2)+10);
			temp[0] = 0;
			strcat(temp,b1);
			strcat(temp,"\n");
			strcat(temp,label);
			strcat(temp," : ");
			strcat(temp,b2);
			$$ = temp;
		}
		|
		NOT '(' boolean ')'
		{	b1 = $3;
			label = "TEFS";
			backpatch(b1,"TRUE","TEFS");
			label = "TRUE";
			backpatch(b1,"FAIL",label);
			label = "FAIL";
			backpatch(b1,"TEFS","FAIL");
			$$ = b1;
		}
		|
		'(' boolean ')'
		{
			$$ = $2;
		}
		|
		TRUE
		{
			return_val = (char*)malloc(20);
			return_val[0] = 0;
			strcat(return_val,"\njump TRUE");
			
			$$ = return_val;
		}
		|
		FALSE
		{
			return_val = (char*)malloc(20);
			return_val[0] = 0;
			strcat(return_val,"\njump FAIL");
			$$ = return_val;
		}
		;

expression:   '(' expression ')'
        {
           $$ = $2;
        }
		|
		unary
		{
			$$ = $1;
		}
		|
        expression '*' expression
        {
	   		expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(20);
			expression_ret->addr = generateNewTemporary();
			return_val = (char*)malloc(200);
			return_val[0] = 0;
			strcat(return_val,expression_ret->addr);
			strcat(return_val,"=");
			strcat(return_val,$1->addr);
			strcat(return_val,"*");
			strcat(return_val,$3->addr);
			temp = (char*)malloc(strlen($1->code)+strlen($3->code)+strlen(return_val)+60);
			temp[0] = 0;
			if ($1->code[0]!=0)
			{
				strcat(temp,$1->code);strcat(temp,"\n");
			}
			if ($3->code[0]!=0)
			{
				strcat(temp,$3->code);strcat(temp,"\n");
			}
			strcat(temp,return_val);
			expression_ret->code = temp;
			$$ = expression_ret;
        }
        |
        expression '/' expression
        {
        	expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(20);
			expression_ret->addr = generateNewTemporary();
			return_val = (char*)malloc(200);
			return_val[0] = 0;
			strcat(return_val,expression_ret->addr);
			strcat(return_val,"=");
			strcat(return_val,$1->addr);
			strcat(return_val,"/");
			strcat(return_val,$3->addr);
			temp = (char*)malloc(strlen($1->code)+strlen($3->code)+strlen(return_val)+60);
			temp[0] = 0;
			if ($1->code[0]!=0)
			{
				strcat(temp,$1->code);strcat(temp,"\n");
			}
			if ($3->code[0]!=0)
			{
				strcat(temp,$3->code);strcat(temp,"\n");
			}
			strcat(temp,return_val);
			expression_ret->code = temp;
			$$ = expression_ret;
	   	}
        |
        expression '%' expression
        {
	   		expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(200);
			expression_ret->addr = generateNewTemporary();
			return_val = (char*)malloc(20);
			return_val[0] = 0;
			strcat(return_val,expression_ret->addr);strcat(return_val,"=");
			strcat(return_val,$1->addr);
			strcat(return_val,"%");
			strcat(return_val,$3->addr);
			temp = (char*)malloc(strlen($1->code)+strlen($3->code)+strlen(return_val)+6);
			temp[0] = 0;
			if ($1->code[0]!=0)
			{
				strcat(temp,$1->code);
				strcat(temp,"\n");
			}
			if ($3->code[0]!=0)
			{
				strcat(temp,$3->code);
				strcat(temp,"\n");
			}
			strcat(temp,return_val);
			expression_ret->code = temp;
			$$ = expression_ret;
        }
        |
        expression '+' expression
        {
	   		expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(200);
			expression_ret->addr = generateNewTemporary();
			return_val = (char*)malloc(20);
			return_val[0] = 0;
			strcat(return_val,expression_ret->addr);
			strcat(return_val,"=");
			strcat(return_val,$1->addr);
			strcat(return_val,"+");
			strcat(return_val,$3->addr);
			temp = (char*)malloc(strlen($1->code)+strlen($3->code)+strlen(return_val)+60);temp[0] = 0;
			if ($1->code[0]!=0)
			{
				strcat(temp,$1->code);strcat(temp,"\n");
			}
			if ($3->code[0]!=0)
			{
				strcat(temp,$3->code);strcat(temp,"\n");
			}
			strcat(temp,return_val);
			expression_ret->code = temp;
			$$ = expression_ret;
        }
        |
        expression '-' expression
        {
	   
        	expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(200);
			expression_ret->addr = generateNewTemporary();
			return_val = (char*)malloc(200);
			return_val[0] = 0;
			strcat(return_val,expression_ret->addr);
			strcat(return_val,"=");
			strcat(return_val,$1->addr);
			strcat(return_val,"-");
			strcat(return_val,$3->addr);
			temp = (char*)malloc(strlen($1->code)+strlen($3->code)+strlen(return_val)+60);
			temp[0] = 0;
			if ($1->code[0]!=0)
			{
				strcat(temp,$1->code);
				strcat(temp,"\n");
			}
			if ($3->code[0]!=0)
			{
				strcat(temp,$3->code);
				strcat(temp,"\n");
			}
			strcat(temp,return_val);
			expression_ret->code = temp;
           	$$ = expression_ret;
		
        }
        |
		text 
		{
			expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(20);
			expression_ret->addr = $1;
			expression_ret->code = (char*)malloc(2);
			expression_ret->code[0] = 0;
			$$ = expression_ret;}
         |
         number 
         {
			expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(20);
			expression_ret->addr = $1;
			expression_ret->code = (char*)malloc(2);
			expression_ret->code[0] = 0;
			$$ = expression_ret;
		}
		|
		'-' number
		{
			expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(20);
			label = generateNewTemporary();
			expression_ret->addr = label;
			return_val = (char*)malloc(20);
			return_val[0] = 0;
			strcat(return_val,label);
			strcat(return_val,"=-");
			strcat(return_val,$2);
			expression_ret->code=return_val;
			$$ = expression_ret;
		}
		|
		text '=' expression
		{
			expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
			expression_ret->addr = (char*)malloc(200);
			expression_ret->addr = generateNewTemporary();
			return_val = (char*)malloc(20);
			return_val[0] = 0;
			strcat(return_val,$1);
			strcat(return_val,"=");
			strcat(return_val,$3->addr);
			temp = (char*)malloc(strlen($3->code)+strlen(return_val)+60);
			temp[0] = 0;
			if ($3->code[0]!=0)
			{
				strcat(temp,$3->code);
				strcat(temp,"\n");
			}
			strcat(temp,return_val);
			expression_ret->code = temp;
			$$ = expression_ret;
		}
		;

list_expr:  list_expr ',' expression
			{
				expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
				expression_ret->code = (char*)malloc(600*sizeof(char));
				strcat(expression_ret->code,$1->code);
				strcat(expression_ret->code,"\n");
				strcat(expression_ret->code,$3->code);
				$$ = expression_ret;
			}
			|
			expression
			{
				expression_ret = (struct expression_type*)malloc(sizeof(struct expression_type));
				expression_ret->code = (char*)malloc(600*sizeof(char));
				strcat(expression_ret->code,$1->code);
				$$ = expression_ret;
			}
			;
text: 	ID
         {
			$$ = $1;
         }
	  ;

number:  DIGIT
        {
			var = (char*)malloc(20);
	        snprintf(var, 10,"%d",$1);
			$$ = var;
        } 
	 	|
        FLOAT
        {
			var = (char*)malloc(20);
	        snprintf(var, 10,"%f",$1);
			$$ = var;
           
        } 
	;
	
%%


extern int yyparse();
extern FILE* yyin;

int main() {
	// open a file handle to a particular file:
	FILE* myfile = fopen("input5.txt", "r");
	// make sure it is valid:
	if (!myfile) {
		printf("I can't open a.snazzle.file!");
		return -1;
	}
	// set lex to read from it instead of defaulting to STDIN:
	yyin = myfile;
	// parse through the input until there is no more:
	do {
		yyparse();
	} while (!feof(yyin));
	
}
void yyerror(char* s) {
	printf("Parsing error.  Message: %s \n",s);
	printf("%d\n",yylineno);
	exit(-1);
}