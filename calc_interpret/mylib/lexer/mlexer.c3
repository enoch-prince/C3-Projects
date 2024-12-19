module mylib::lexer::mlexer;

import std::ascii;
import std::io;

fault NonTokenFault
{
    WHITESPACE_FAULT
}

enum Token_Kind {
    END,
    INVALID_TOKEN,
    IDENTIFIER,         // x, a, b
    KEYWORD,            // => cos, sin, tan
    SEMI_COLON,         // ;
    CLOSE_PARENTHESIS,  // )
    OPEN_PARENTHESIS,   // (
    OPERATOR_ADD,       // +
    OPERATOR_SUB,       // -
    OPERATOR_DIV,       // /
    OPERATOR_MULT,      // *
    OPERATOR_MOD,       // %
    OPERATOR_EXP,       // e, E
    FACTORIAL,          // !
    NUMBER,             // 1, 2, 6.02e23
    POWER,             // ^
    COMMENT,            // #
    WHITESPACE
}

const String[*] KEYWORDS = {"cos", "sin", "tan", "atan", "atan2", "sqrt"};

struct Token {
    Token_Kind type;
    String value;
    usz pos;
}

fn void Token.init(Token* this) {
    this.type = Token_Kind.END;
    this.value = "";
    this.pos = 0;
}

fn void Token.print(Token* this) {
    io::printfn("type: %s | value: '%s' | pos: %d", this.type, this.value, this.pos);
}

struct Lexer {
    String content;
    usz cursor;
    usz bot; // beginning of token
}

fn void Lexer.init(Lexer* this, String content) {
    this.content = content;
    this.bot = 0;
    this.cursor = 0;
}

fn Token! Lexer.next(Lexer* this) {
    Token token;
    token.init();

    if (this.cursor >= this.content.len) return token;

    token.pos = this.bot;

    char val = this.content[this.cursor];
    usz look_ahead = this.cursor;
    if (ascii::is_digit(val)) {
        while(ascii::is_digit(val) || val == '.') {
            // io::printfn("digit: %c", val);
            look_ahead++;
            if (look_ahead >= this.content.len) break;
            val = this.content[look_ahead];
        }
        token.type = Token_Kind.NUMBER;
        look_ahead--; // hack: deals with overstepped cursor
        this.cursor = look_ahead;
    }
    else if (ascii::is_alpha(val)) {
        while(ascii::is_alpha(val)) {
            // io::printfn("alpha: %c", val);
            look_ahead++;
            if (look_ahead >= this.content.len) break;
            val = this.content[look_ahead];
        }
        look_ahead--; // hack: deals with overstepped cursor
        if (look_ahead > this.cursor) {
            String search_string = this.content[this.cursor .. look_ahead];
            search_string.convert_ascii_to_lower();
            usz! found_index = array::index_of(KEYWORDS, search_string);
            if (catch err = found_index) {
                io::eprintf("[Lexer] Error: '%s' is not a keyword. Keywords are: ", search_string);
                io::eprintn(KEYWORDS);
                io::eprintfn("\tIf your intention was an identifier, then use single letters, e.g., 'x', 'y', etc.");
                io::eprintfn("\tElse you could just say x*y or m*n, instead of xy and mn 😎");
                return err?;
            }
            token.type = Token_Kind.KEYWORD;
            this.cursor = look_ahead;
        }
        else {
            val = this.content[look_ahead]; // this is needed since look ahead was modified by the hack
            if (val == 'e' || val == 'E') {
                token.type = Token_Kind.OPERATOR_EXP;
            }
            else {
                token.type = Token_Kind.IDENTIFIER;
            }
        }

    }
    else if (ascii::is_space(val)) {
        // io::printfn("space: '%c'", val);
        while(ascii::is_space(val)) {
            look_ahead++;
            if (look_ahead >= this.content.len) break;
            val = this.content[look_ahead];
        }
        token.type = Token_Kind.WHITESPACE;
        look_ahead--; // hack: deals with overstepped cursor
        this.cursor = look_ahead;
    }
    else {
            //TODO: Rewrite for maintainability
            switch (val)
            {
                case '(':
                    token.type = Token_Kind.OPEN_PARENTHESIS;
                case ')':
                    token.type = Token_Kind.CLOSE_PARENTHESIS;
                case '+':
                    token.type = Token_Kind.OPERATOR_ADD;
                case '-':
                    token.type = Token_Kind.OPERATOR_SUB;
                case '*':
                    token.type = Token_Kind.OPERATOR_MULT;
                case '/':
                    token.type = Token_Kind.OPERATOR_DIV;
                case '%':
                    token.type = Token_Kind.OPERATOR_MOD;
                case '^':
                    token.type = Token_Kind.POWER;
                case '!':
                    token.type = Token_Kind.FACTORIAL;
                default:
                    token.type = Token_Kind.INVALID_TOKEN;
            }
    }
    
    // io::printfn("bot: %d", this.bot);
    // io::printfn("cursor: %d\n", this.cursor);
    token.value = this.content[this.bot .. this.cursor];
    this.cursor++;
    this.bot = this.cursor;
    return token;
}