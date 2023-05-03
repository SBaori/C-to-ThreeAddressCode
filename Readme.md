## Build

```bash
  yacc -d yacc.y
  flex lex.l
  gcc y.tab.c lex.yy.c -o generator
```
## Run

```
  ./generator < input.txt
```
