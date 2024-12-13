module mylib::parser::mparser;

import mylib::lexer::mlexer;
import std::io;

// The job of the parser is to determine if the tokenized expression is a valid 
// executable math expression ref: https://en.wikipedia.org/wiki/Parsing#Parser
// And converts the expression into an Abstract Syntax Tree (AST)

// 1. Some sort of a Rule System
//      RULES:
//      -----
//      a. Invalid tokens should be bounced
//      b. No closing parenthesis allowed without an opening parenthesis
//      c. Every opening parenthesis must have a corresponding closing parenthesis

// 2. Validate the Rules

// 3. Convert to executable c3 mathematical expression

// 4. Evaluate the expression


fault PaserFault
{
    MATH_SYNTAX_ERROR,
    INVALID_SYMBOL
}

// AST Type ENUM
//  - NUMBER
//  - Unary Operator
//  - Binary Operator
//  - Function Call
//  - Identifier
enum ASTType {
    AST_NUMBER,
    AST_UNARY_OP,
    AST_BINARY_OP,
    AST_FUNCION_CALL,
    AST_IDENTIFIER,
    AST_NONE
}

// AST Structure
// - Type
// - Left Node
// - Right Node
// - Value
struct ASTNode{
    ASTType type;
    String value;
    ASTNode* left;
    ASTNode* right;
}

struct Private @private { int parenthesis_count; }

struct Mparser{
    inline Private private_field;
    Allocator allocator;
    Lexer* lexer;
    Token current_token;
}

fn void! Mparser.init(Mparser* this, Lexer* lexer, Allocator allocator = allocator::heap()) {
    this.allocator = allocator;
    this.lexer = lexer;
    // this.current_token = this.lexer.next()!;
    this.parenthesis_count = 0;
    this.advance()!;
}

fn void! Mparser.temp_init(Mparser* this, Lexer* lexer) {
    this.init(lexer, allocator::temp())!;
}

fn ASTNode*! Mparser.parse(Mparser* this) {
    return this.parse_expression()!;

}

fn void! Mparser.advance(Mparser* this) @private {
    this.current_token = this.lexer.next()!;
    if (this.current_token.type == Token_Kind.OPEN_PARENTHESIS ||
        this.current_token.type == Token_Kind.CLOSE_PARENTHESIS) {
        this.parenthesis_count = (this.current_token.type == Token_Kind.OPEN_PARENTHESIS) ? this.parenthesis_count+1:this.parenthesis_count-1;
        io::printfn("[Mparser] Parenthesis Count %d", this.parenthesis_count);
    }
    if (this.current_token.type == Token_Kind.WHITESPACE) {
        this.advance()!;
    }
    if (this.parenthesis_count < 0) {
        // expected a '(' before expression
        io::eprintf("[Mparser] MATH SYNTAX ERROR: unexpected symbol '%s' at position %d\n", this.current_token.value, this.current_token.pos);
        return PaserFault.MATH_SYNTAX_ERROR?;
    }
    else if (this.parenthesis_count > 0 && this.lexer.cursor >= this.lexer.content.len) {
        // expected a ')' after expression
        io::eprintf("[Mparser] MATH SYNTAX ERROR: expected symbol ')' at position %d\n", this.current_token.pos);
        return PaserFault.MATH_SYNTAX_ERROR?;
    }
    
}

fn void! Mparser.expect(Mparser* this, Token token) @private {
    if (this.current_token.type != token.type) {
        if (!this.current_token.value) {
            this.current_token.value = "NULL";
            token.pos = this.lexer.cursor;
        }
        io::eprintf("[Mparser] Math Syntax Error: Expected token '%s' at position %d, but got '%s'\n", token.value, token.pos, this.current_token.value);
        return PaserFault.MATH_SYNTAX_ERROR?;
    }
    this.advance()!;
}

fn void Mparser.free(&self, ASTNode* node)
{
	if (!self.allocator || !node) return;

    switch (node.type)
    {
    case AST_IDENTIFIER:
    case AST_NUMBER:
        allocator::free(self.allocator, node);
    case AST_UNARY_OP:
    case AST_FUNCION_CALL:
        self.free(node.left);
    case AST_BINARY_OP:
        self.free(node.left);
        self.free(node.right);
    default:
        return;
    }
}

fn void Mparser.print_tree(&self, ASTNode* node, int depth = 0)
{
	if (!self.allocator) return;

    // Indent based on depth
    for (int i = 0; i < depth; i++) {
        io::print("  ");
    }

    switch (node.type)
    {
    case AST_IDENTIFIER:
        io::printfn("ASTNode(IDENTIFIER, value='%s')", node.value);
    case AST_NUMBER:
        io::printfn("ASTNode(NUMBER, value='%s')", node.value);
    case AST_UNARY_OP:
        io::printfn("ASTNode(UNARY_OP, op='%s')", node.value);
        self.print_tree(node.left, depth + 1);
    case AST_FUNCION_CALL:
        io::printfn("ASTNode(FUNCTION_CALL, func_name='%s')", node.value);
        self.print_tree(node.left, depth + 1);
    case AST_BINARY_OP:
        io::printfn("ASTNode(BINARY_OP, op='%s')", node.value);
        self.print_tree(node.left, depth + 1);
        self.print_tree(node.right, depth + 1);
    default:
        io::printn("ASTNode(UNKNOWN)");
    }
}

<*
Handles '+' and '-' expressions
*>
fn ASTNode*! Mparser.parse_expression(Mparser* this) @private {
    // io::printn("Parsing expression: '+' or '-' ");
    ASTNode* node = this.parse_div_mult_mod()!;
    ASTNode* main_node = this.alloc_node();
    main_node.type = AST_NONE;

    while (this.current_token.type == Token_Kind.OPERATOR_ADD || 
            this.current_token.type == Token_Kind.OPERATOR_SUB) {
                ASTNode* next_node = null;
                if (main_node.type != AST_NONE) { // iteration after first
                    next_node = this.alloc_node();
                    *next_node = { .type=main_node.type, .value=main_node.value, .left=main_node.left, .right=main_node.right };
                }
                String current_token_value = this.current_token.value;
                this.advance()!;
                ASTNode* right_node = this.parse_div_mult_mod()!;

                *main_node = { .type = AST_BINARY_OP, .value = current_token_value, .left = (!next_node)?node:next_node, .right = right_node };
                
            }
    // io::printn("PARSE_EXPR_END");
    if (main_node.type == AST_NONE) { 
        this.free(main_node);
        return node; 
    }
    else { return main_node; }
}

<*
Handles '/', '*' and '%' expressions
*>
fn ASTNode*! Mparser.parse_div_mult_mod(Mparser* this) @private {
    // io::printn("Parsing div, mult & mod: '/','*' or '%' ");
    ASTNode* node = this.parse_finp()!;
    ASTNode* main_node = this.alloc_node();
    main_node.type = AST_NONE;

    if (this.current_token.type == Token_Kind.OPERATOR_DIV || 
           this.current_token.type == Token_Kind.OPERATOR_MULT ||
           this.current_token.type == Token_Kind.OPERATOR_MOD) 
        {
            String current_token_value = this.current_token.value;
            this.advance()!;
            ASTNode* right_node = this.parse_finp()!;
            *main_node = { .type = AST_BINARY_OP, .value = current_token_value, .left = node, .right = right_node };
        }
    // io::printn("PARSE_DIV_MUL_MOD_END");
    if (main_node.type == AST_NONE) { 
        this.free(main_node);
        return node; 
    }
    else { return main_node; }
}

<* 
Handles Functions, Identifiers, Numbers, Parenthesis (FINP)
*>
fn ASTNode*! Mparser.parse_finp(Mparser* this) @private {
    // io::print("Parsing finp: ");

    switch (this.current_token.type)
    {
    case Token_Kind.NUMBER:
        ASTNode* node = this.alloc_node();
        *node = { .type = AST_NUMBER, .value = this.current_token.value, .left = null, .right = null };
        // io::printfn("%s -> %s", this.current_token.type, this.current_token.value);
        this.advance()!;
        // io::printn("PARSE_FINP_END");
        return node;
    case Token_Kind.IDENTIFIER:
        ASTNode* node = this.alloc_node();
        *node = { .type = AST_IDENTIFIER, .value = this.current_token.value, .left = null, .right = null };
        // io::printfn("%s", this.current_token.type);
        this.advance()!;
        // io::printn("PARSE_FINP_END");
        return node;
    case Token_Kind.OPEN_PARENTHESIS:
        // io::printfn("%s", this.current_token.type);
        this.advance()!; // skip '('
        ASTNode* parse_node = this.parse_expression()!;
        this.expect({.type=Token_Kind.CLOSE_PARENTHESIS, .value=")", .pos=this.current_token.pos})!;
        // io::printn("PARSE_FINP_END");
        return parse_node;
    case Token_Kind.KEYWORD:
        // io::printf("%s", this.current_token.type);
        ASTNode* parse_node = this.parse_function()!;
        // io::printn("PARSE_FINP_END");
        return parse_node;
    case Token_Kind.END:
        // io::printfn("%s", this.current_token.type);
        // io::printn("PARSE_FINP_END");
        return null;
    default:
        io::eprintf("[Mparser] ERROR: Invalid Symbol '%s'\n", this.current_token.type);
        // io::printn("PARSE_FINP_END");
        return PaserFault.INVALID_SYMBOL?;   
    }
}

<*
Handles function like sin, cos, tan, etc..
*>
fn ASTNode*! Mparser.parse_function(Mparser* this) @private {
    // io::printfn(" -> %s", this.current_token.value);
    ASTNode* node = this.alloc_node();
    *node = { .type = AST_FUNCION_CALL, .value = this.current_token.value, .left = null, .right = null };
    this.advance()!;
    this.expect({.type=Token_Kind.OPEN_PARENTHESIS, .value="(", .pos=this.current_token.pos})!;
    node.left = this.parse_expression()!;
    this.expect({.type=Token_Kind.CLOSE_PARENTHESIS, .value=")", .pos=this.current_token.pos})!;
    // io::printn("PARSE_FUNCTION_END");
    return node;
}


////////////// MACROS ////////////////
<*
 @require self.allocator
*>
macro ASTNode* Mparser.alloc_node(&self) @private
{
	if (!self.allocator) self.allocator = allocator::heap();
	return allocator::alloc(self.allocator, ASTNode);
}

