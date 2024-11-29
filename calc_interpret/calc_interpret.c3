module calc_interpret;

import std::io;
import std::collections::list;
import mylib::lexer::mlexer;

def TokenList_t = List(<mlexer::Token>);

fn void! main()
{
    io::printn("\nHello, welcome to Calc-Intepret!");
    io::printn("Enter any mathematical expression like you would in a book.");
    io::print("Enter your input: ");

    // Get User Input
    String! user_input = io::readline();
    if (catch excuse = user_input) {
        io::printn("Oops...something went wrong!");
        return excuse?;
    }
    io::printfn("Your input: %s", user_input);

    // Parse the Input
    String trimmed_input = user_input.trim();
    usz input_length = trimmed_input.len;
    io::printfn("Trimmed input:%s", trimmed_input);
    io::printfn("Trimmed input Length: %d", input_length);

    // 1. Lexer
    mlexer::Lexer lexer;
    lexer.init(user_input);

    // 2. Tokenize    
    TokenList_t tokens;
    tokens.new_init();
    defer tokens.free();

    while(lexer.cursor < lexer.content.len) {

        mlexer::Token! retrieved_token = lexer.next();
        if (catch err = retrieved_token) {
            case NonTokenFault.WHITESPACE_FAULT:
                io::printn("[Lexer] Whitespace encountered. Skipping.. 😎");
                continue;
            default:
                return;
            
        }
        tokens.push(retrieved_token);
    }


    io::printn("\nTokens:\n-------");
    foreach (toke : tokens)
    {
        toke.print();
    }
}