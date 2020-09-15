package chocopy.pa1;
import java_cup.runtime.*;
import java.util.*;
import java.io.StringReader;

%%

/*** Do not change the flags below unless you know what you are doing. ***/

%unicode
%line
%column

%class ChocoPyLexer
%public

%cupsym ChocoPyTokens
%cup
%cupdebug

%eofclose    false

/*** Do not change the flags above unless you know what you are doing. ***/

/* The following code section is copied verbatim to the
 * generated lexer class. */
%{
    /* The code below includes some convenience methods to create tokens
     * of a given type and optionally a value that the CUP parser can
     * understand. Specifically, a lot of the logic below deals with
     * embedded information about where in the source code a given token
     * was recognized, so that the parser can report errors accurately.
     * (It need not be modified for this project.) */

    /** Producer of token-related values for the parser. */
    final ComplexSymbolFactory symbolFactory = new ComplexSymbolFactory();

    /** Track our indentation level. */
    final Stack<Integer> indentations = new Stack<>();

    /** Return a terminal symbol of syntactic category TYPE and no
     *  semantic value at the current source location. */
    private Symbol symbol(int type) {
        return symbol(type, yytext());
    }

    /** Return a terminal symbol of syntactic category TYPE and semantic
     *  value VALUE at the current source location. */
    private Symbol symbol(int type, Object value) {
        return symbolFactory.newSymbol(ChocoPyTokens.terminalNames[type], type,
            new ComplexSymbolFactory.Location(yyline + 1, yycolumn + 1),
            new ComplexSymbolFactory.Location(yyline + 1,yycolumn + yylength()),
            value);
    }

    /* Calcualte the indentation level according to the Python language grammer.
       1. Leading whitespace is used to compute the indentation.
       2. Tabs are replaced (left -> right) into a number between [1, 8] such that the current number of spaces
          is divisible by 8.
       3. The total number of spaces determines the indentation.
    */
    private Symbol calculateIndentation(String whitespace) {
        // lets safeguard against being called improperly
        assert whitespace.isBlank() : "This was called with a non whitespace string";
        int indentation = 0;
        for (char c : whitespace.toCharArray()) {
            switch (c) {
                case '\t':
                    for (int i = 1; i <= 8; i++) {
                        if ( (indentation + i) % 8 == 0) {
                          indentation += i;
                          break;
                        }
                    }
                    throw new IllegalArgumentException("Could not find a tabstop length.");
                case ' ':
                    indentation += 1;
                    break;
                default:
                    throw new IllegalArgumentException("Unknown whitespace character.");
            }
        }

        yybegin(LOGICAL_LINE);

        // case 1: If it is equal, nothing happens.
        if (indentations.peek() == indentation) {
            return null;
        }

        // case 2: If it is larger, it is pushed on the stack, and one INDENT token is generated
        if (indentation > indentations.peek()) {
            indentations.push(indentation);
            return symbol(ChocoPyTokens.INDENT);
        }

        // case 3: If it is smaller, it must be one of the numbers occurring on the stack; all numbers on the stack
        //         that are larger are popped off, and for each number popped off a DEDENT token is generated.
        if (indentation < indentations.peek()) {
            indentations.pop();
            // reset the whitespace read; this causes us to potentially emit multiple dedents
            yypushback(yylength());
            yybegin(YYINITIAL);

            // if it is larger than the top of the stack; then we have the wrong indentation numbers
            // lets put a UNRECOGNIZED
            if (indentation > indentations.peek()) {
                return symbol(ChocoPyTokens.UNRECOGNIZED);
            }
            return symbol(ChocoPyTokens.DEDENT);
        }

        throw new IllegalStateException("Should never hit here");
    }

%}

/* The code enclosed in %init{ and %init} is copied verbatim into the constructor of the generated class. */
%init{
indentations.push(0);
%init}

/* Macros (regexes used in rules below) */

WhiteSpace = [ \t]
NotWhiteSpace = [^ \t]
LineBreak  = \r|\n|\r\n
InputCharacter = [^\r\n]
Comment = #{InputCharacter}*{LineBreak}?
IntegerLiteral = 0 | [1-9][0-9]*

/* A logical line is a non-blank line that is not a comment. */
LogicalLine = {WhiteSpace}*[[^ \t]--#]
CommentLine = {WhiteSpace}*{Comment}

%state LOGICAL_LINE
%%


<YYINITIAL> {

  /* This must bea blank line. */
  {LineBreak}                { /* ignore */ }

  /* Comments. Comments will not print out a NEWLINE symbol. */
  {CommentLine}                  { /* ignore */  }

  /* Whitespace. A logical line is a physical line that contains at least one token that is not whitespace or comments. */
  {LogicalLine}                {
                                        yypushback(1); // put back the character read
                                        final Symbol sym = calculateIndentation(yytext());
                                        if (sym != null) {
                                            return sym;
                                        }
                               }
}

<LOGICAL_LINE> {

  /* Delimiters. */
  {LineBreak}                 { yybegin(YYINITIAL); return symbol(ChocoPyTokens.NEWLINE); }

  /* Comments. Comments will not print out a NEWLINE symbol. */
  {Comment}                   { yybegin(YYINITIAL); /* ignore */  }

  /* Literals. */
  {IntegerLiteral}            { return symbol(ChocoPyTokens.NUMBER,
                                               Integer.parseInt(yytext())); }
}

<<EOF>>                       {
                                if (indentations.size() > 1) {
                                    indentations.pop();

                                    int line = yyline;
                                    int column = yycolumn;
                                    yyreset(new StringReader(""));
                                    yyline = line;
                                    yycolumn = column;
                                    return symbol(ChocoPyTokens.DEDENT);
                                }
                                return symbol(ChocoPyTokens.EOF);
                              }

/* Error fallback. */
[^]                           { return symbol(ChocoPyTokens.UNRECOGNIZED); }