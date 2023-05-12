# Features Implemented

1) data types supported - int, float and char
2) multi variable declaration and assigment
3) if and if-else
4) for and while loops
5) evaluation of boolean expressions (backpatching)

## Planned to add
1) multi dimensional arrays

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
