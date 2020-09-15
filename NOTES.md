# WebServer

A web-server is included; however due to limitations by browsers for CORS, you can't simply open the file://
in the browser; you should run a local server.

```bash
python3 -m http.server --directory ./web/
```

## Scanner

If you would like to only run the scanner, you can do by providing a the lexer class specifically.

```bash
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.pa1.ChocoPyLexer <input file>
```

You can run the **reference** Lexer with the following command
```bash
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.reference.ChocoPyLexer <input file>
```