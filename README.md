# C_to_Jasmin_Comiler
Using lex and yacc to form a compiler which can convert C code to java assembly code(Jasmin instruction).
## File discription
- compiler_hw3.l  
It is a lexical analyzer(scanner). The scanner transforms a character stream of source program into a token stream.  
- lex.yy.c  
The input (.l) is translated to a C program (lex.yy.c).
- compiler_hw3.y  
It is a syntax analyzer(parser). Parser uses grammar rules that allow it to analyze tokens from Lex and create a syntax tree.  
It is also a code generator that generates the Java Assembly code.
- y.tab.c  
The input (.y) is translated to a C program (y.tab.c).
## Execution flow
![image](https://i.imgur.com/hfNZIpm.png)
![image](https://i.imgur.com/jbB8MRv.png)
## Workflow
- Build the compiler by make command and will get an executable named mycompiler.
- Run the compiler using the command $ ./mycompiler < input.c , which is built by lex and yacc, with the given μC code ( .c file) to generate the corresponding Java assembly code ( .j file).
- The Java assembly code can be converted into the Java Bytecode ( .class file) through the Java assembler, Jasmin, i.e., use $ java -jar jasmin.jar hw3.j to generate Main.class .
- Run the Java program ( .class file) with Java Virtual Machine (JVM); the program should generate the execution results required by this assignment, i.e., use $ java Main.class to run the executable.

