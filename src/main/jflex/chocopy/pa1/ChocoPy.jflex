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

    /** The current indentation (# of spaces) **/
    int indentation = 0;

    /** String buffer to hold literals. */
    StringBuffer string = new StringBuffer();

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

    private Symbol symbol(String value) {
        int type = ChocoPyTokens.STRING;
        int column = yycolumn - value.length();
        return symbolFactory.newSymbol(ChocoPyTokens.terminalNames[type], type,
            new ComplexSymbolFactory.Location(yyline + 1, column),
            new ComplexSymbolFactory.Location(yyline + 1, column + value.length()),
            value);
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
StringCharacter = [^\r\n\"\\]
StringLiteral = \" ({StringCharacter} | \\t | \\n | \\ | \\\") * \"

/* A logical line is a non-blank line that is not a comment. */
LogicalLine = {WhiteSpace}*[[^ \t]--#]
CommentLine = {WhiteSpace}*{Comment}


%state LOGICAL_LINE
%state INDENT
%%


<YYINITIAL> {

  /* This must be a blank line. */
  {LineBreak}                { /* ignore */ }

  /* Comments. Comments will not print out a NEWLINE symbol. */
  {CommentLine}                  { /* ignore */  }

  /* A logical line is a physical line that contains at least one token that is not whitespace or comments. */
  {LogicalLine}                {
                                    indentation = 0;
                                    // put back the characters to read
                                    yypushback(yylength());
                                    yybegin(INDENT);
                               }
}

<INDENT> {

    " "                       {
                                indentation += 1;
                              }

    \t                        {
                                // convert a tab to the number of spaces needed so that it's divisible by 8
                                indentation += (8 - (indentation % 8));
                              }

    /* Anything. */
    .                         {
                                // push back the entry so that it can re-read
                                yypushback(1);

                                // case 1: If it is larger, it is pushed on the stack, and one INDENT token is generated
                                if (indentation > indentations.peek()) {
                                    indentations.push(indentation);
                                    yybegin(LOGICAL_LINE);
                                    return symbol(ChocoPyTokens.INDENT);
                                }

                                // case 2: If it is smaller, pop one off the stack.
                                if (indentation < indentations.peek()) {
                                    indentations.pop();
                                    return symbol(ChocoPyTokens.DEDENT);
                                }

                                // case 3: If it is the same, then do not emit anything
                                if (indentation == indentations.peek()) {
                                    yybegin(LOGICAL_LINE);
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

  /* String
    Done as a single regex so that the debug printing that uses yytext looks correct.
    @see https://stackoverflow.com/a/29685286/143733
  */
  {StringLiteral}              { return symbol(ChocoPyTokens.STRING, yytext()); }

  /* Keywords */
  "False"                       { return symbol(ChocoPyTokens.FALSE); }
  "None"                        { return symbol(ChocoPyTokens.NONE); }
  "True"                        { return symbol(ChocoPyTokens.TRUE); }
  "and"                         { return symbol(ChocoPyTokens.AND); }
  "as"                          { return symbol(ChocoPyTokens.AS); }
  "assert"                      { return symbol(ChocoPyTokens.ASSERT); }
  "async"                       { return symbol(ChocoPyTokens.UNUSED); }
  "await"                       { return symbol(ChocoPyTokens.UNUSED); }
  "break"                       { return symbol(ChocoPyTokens.BREAK); }
  "class"                       { return symbol(ChocoPyTokens.CLASS); }
  "continue"                    { return symbol(ChocoPyTokens.CONTINUE); }
  "def"                         { return symbol(ChocoPyTokens.DEF); }
  "del"                         { return symbol(ChocoPyTokens.DEL); }
  "elif"                        { return symbol(ChocoPyTokens.ELIF); }
  "else"                        { return symbol(ChocoPyTokens.ELSE); }
  "except"                      { return symbol(ChocoPyTokens.EXCEPT); }
  "finally"                     { return symbol(ChocoPyTokens.FINALLY); }
  "for"                         { return symbol(ChocoPyTokens.FOR); }
  "from"                        { return symbol(ChocoPyTokens.FROM); }
  "global"                      { return symbol(ChocoPyTokens.GLOBAL); }
  "if"                          { return symbol(ChocoPyTokens.IF); }
  "import"                      { return symbol(ChocoPyTokens.IMPORT); }
  "in"                          { return symbol(ChocoPyTokens.IN); }
  "is"                          { return symbol(ChocoPyTokens.IS); }
  "lambda"                      { return symbol(ChocoPyTokens.LAMBDA); }
  "nonlocal"                    { return symbol(ChocoPyTokens.NONLOCAL); }
  "not"                         { return symbol(ChocoPyTokens.NOT); }
  "or"                          { return symbol(ChocoPyTokens.OR); }
  "pass"                        { return symbol(ChocoPyTokens.PASS); }
  "raise"                       { return symbol(ChocoPyTokens.RAISE); }
  "return"                      { return symbol(ChocoPyTokens.RETURN); }
  "try"                         { return symbol(ChocoPyTokens.TRY); }
  "while"                       { return symbol(ChocoPyTokens.WHILE); }
  "with"                        { return symbol(ChocoPyTokens.WITH); }
  "yield"                       { return symbol(ChocoPyTokens.YIELD); }


  {WhiteSpace}                  { /* Do nothing. */ }
}

<<EOF>>                       {
                                if (indentations.size() > 1) {
                                    indentations.pop();

                                    int line = yyline;
                                    int column = yycolumn;
                                    zzAtEOF = false;
                                    return symbol(ChocoPyTokens.DEDENT);
                                }
                                return symbol(ChocoPyTokens.EOF);
                              }

/* Error fallback. */
[^]                           { return symbol(ChocoPyTokens.UNRECOGNIZED); }