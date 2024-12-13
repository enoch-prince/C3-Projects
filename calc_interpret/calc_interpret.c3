module calc_interpret;

import std::io;
import std::collections::list;
import mylib::lexer::mlexer;
import mylib::parser::mparser;
import mylib::evaluator::mevaluator;

// TODO: implement parser for unary operator
// TODO: implement tokenization for 10e5 or 10^5, 10e-5 or 10^(-5) or 10^-5
// TODO: implement parser for '^' and 'e'

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
    // io::printfn("Your input: %s", user_input);

    // Parse the Input
    String trimmed_input = user_input.trim();
    usz input_length = trimmed_input.len;
    io::printfn("Trimmed input:%s\n", trimmed_input);
    // io::printfn("Trimmed input Length: %d", input_length);

    // 1. Lexer
    mlexer::Lexer lexer;
    lexer.init(user_input);

    // Parse
    mparser::Mparser parser;
    parser.init(&lexer)!;

    ASTNode*! ast = parser.parse();

    if (catch err = ast) {
        io::eprint("[Main Exec] Somthing went wrong.. ");
        io::eprintn(err);
        return err?;
    }

    defer parser.free(ast);
    io::printn("\nAST:\n------");
    parser.print_tree(ast, 0);

    double! result = mevaluator::mevaluate(ast);
    if (catch err = result) {
        io::eprint("[Main Exec] Somthing went wrong.. ");
        io::eprintn(err);
        return err?;
    }
    io::printn("\nResults:\n------");
    io::printfn("[Evaluator] %s = %.2f", trimmed_input, result);

    // 2. Testing Tokenization    
    // TokenList_t tokens;
    // tokens.new_init();
    // defer tokens.free();

    // while(lexer.cursor < lexer.content.len) {

    //     mlexer::Token! retrieved_token = lexer.next();
    //     if (catch err = retrieved_token) {
    //         return err?;
            
    //     }
    //     tokens.push(retrieved_token);
    // }


    // io::printn("\nTokens:\n-------");
    // foreach (toke : tokens)
    // {
    //     toke.print();
    // }
}