yacc -d yacc.y -Wcounterexamples
flex lex.l
gcc lex.yy.c y.tab.c -o generator
