## Build

```bash
  yacc -d yacc.y
  flex lex.l
  gcc y.tab.c lex.yy.c -o generator
```
or

```
  ./build.sh
```

## Run

```
  ./generator < input.txt
```
